import os
import sys
import mimetypes
from email.message import EmailMessage
from email.utils import make_msgid
from bs4 import BeautifulSoup

def create_eml(input_folder, output_file):
    """
    Creates an EML file from HTML with embedded images.

    Args:
        input_folder: Folder containing index.html and img/
        output_file: Path to the EML file to generate
    """
    html_file = os.path.join(input_folder, "index.html")

    if not os.path.exists(html_file):
        print(f"❌ Error: Cannot find {html_file}")
        return False

    msg = EmailMessage()
    msg['Subject'] = "HTML Template"
    msg['X-Unsent'] = '1'

    with open(html_file, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    images_to_attach = []

    # Find images and replace src with CID
    for img_tag in soup.find_all('img'):
        src = img_tag.get('src')
        if not src: continue

        # Ignore external images (http/https)
        if src.startswith('http'): continue

        cid = make_msgid(domain='img')[1:-1]
        img_tag['src'] = f"cid:{cid}"

        # Build path relative to input_folder
        full_path = os.path.join(input_folder, src)
        images_to_attach.append({'path': full_path, 'cid': cid})

    msg.add_alternative(str(soup), subtype='html')

    # Attach images with proper headers for Outlook Classic compatibility
    for img in images_to_attach:
        if os.path.exists(img['path']):
            with open(img['path'], 'rb') as f:
                data = f.read()
                mime_type = mimetypes.guess_type(img['path'])[0] or 'application/octet-stream'
                main, sub = mime_type.split('/')
                filename = os.path.basename(img['path'])

                # Add image with explicit Content-Disposition: inline
                msg.get_payload()[0].add_related(
                    data,
                    maintype=main,
                    subtype=sub,
                    cid=f"<{img['cid']}>",
                    filename=filename,
                    disposition='inline'
                )
        else:
            print(f"⚠️ Warning: Image not found -> {img['path']}")

    with open(output_file, 'wb') as f:
        f.write(msg.as_bytes())
    print(f"✅ Python: EML generated successfully -> {output_file}")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 generate_eml.py <input_folder> <output_file>")
        print("Example: python3 generate_eml.py mail/if_nl_adyen_new_es output.eml")
        sys.exit(1)

    folder = sys.argv[1]
    output = sys.argv[2]

    if not create_eml(folder, output):
        sys.exit(1)
