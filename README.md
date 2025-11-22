# HTML to Outlook Template Converter

> Convert HTML email templates with embedded images into native Outlook Template Files (.oft)

A Docker-based pipeline that combines Python and .NET to seamlessly transform HTML emails into native Outlook templates, preserving all inline images and formatting.

## Features

- **Batch Processing**: Automatically process multiple email templates from different folders
- **Image Embedding**: Converts local images to Content-ID (CID) references for proper email embedding
- **Docker-Based**: No local dependencies required - everything runs in containers
- **Simple Workflow**: Drop your HTML + images in a folder, get ready-to-use .oft files
- **Production Ready**: Built to handle real-world email templates with complex layouts

## Quick Start

### Prerequisites

- Docker Desktop installed ([Download here](https://www.docker.com/products/docker-desktop))

### Installation

1. Clone this repository:

```bash
git clone https://github.com/jaimegvalero/html2oft-converter.git
cd html2oft-converter
```

2. Prepare your email templates in the `mail/` directory:

```
mail/
├── welcome_email/
│   ├── index.html
│   └── img/
│       ├── logo.png
│       └── banner.jpg
└── newsletter/
    ├── index.html
    └── img/
        └── header.png
```

3. Run the converter:

```bash
docker compose up --build
```

4. Find your `.oft` files in the `output/` directory:

```
output/
├── welcome_email.oft
└── newsletter.oft
```

## How It Works

The conversion follows a 3-stage pipeline:

```
HTML + Images  →  Python (EML)  →  .NET (OFT)  →  Outlook Template
```

1. **Python Stage** (`generate_eml.py`):

   - Parses HTML file using BeautifulSoup4
   - Extracts local images and converts `src` attributes to CID references
   - Generates RFC-compliant EML file with embedded images

2. **.NET Stage** (`Program.cs`):

   - Reads EML using MimeKit
   - Converts to MSG format using MsgKit 2.3.0
   - Exports as native Outlook Template (.oft)

3. **Docker Orchestration** (`compose.yml`):
   - Manages the multi-stage build process
   - Handles dependencies (.NET SDK 8.0, Python 3, libraries)
   - Executes batch processing script

## Usage

### Batch Processing (Recommended)

Process all templates in the `mail/` directory:

```bash
docker compose up --build
```

This will:

- Build the Docker image with all dependencies
- Process each folder in `mail/`
- Generate individual `.oft` files named after their source folders
- Display a summary with success/failure counts

**Note**: Only use `--build` when you modify the Dockerfile or dependencies. For subsequent runs with just email changes, use `docker compose up`.

### Single Template Conversion

To process a single email manually:

```bash
# Generate EML
python3 generate_eml.py mail/welcome_email temp/output.eml

# Convert to OFT (requires .NET 8.0 SDK)
cd /path/to/dotnet/project
dotnet run /path/to/input.eml /path/to/output.oft
```

## Project Structure

```
.
├── generate_eml.py        # Python: HTML → EML converter
├── Program.cs             # C#: EML → OFT converter
├── process_all.sh         # Bash: Batch processing orchestrator
├── Dockerfile             # Multi-stage build configuration
├── compose.yml            # Docker Compose orchestration
├── mail/                  # Input: Email template folders
│   └── {template_name}/
│       ├── index.html     # HTML email template
│       └── img/           # Images referenced in HTML
├── output/                # Output: Generated .oft files
└── temp/                  # Temporary .eml files
```

## Technical Details

### Image Handling

The converter processes images in two ways:

1. **Local images** (`img/logo.png`, etc.) → Embedded as inline attachments with CID references
2. **External URLs** (https://example.com/image.png) → Left unchanged as external references

### Dependencies

- **Python**: BeautifulSoup4 for HTML parsing
- **.NET**: MsgKit 2.3.0 and MimeKit for email/MSG handling
- **Docker**: .NET SDK 8.0 base image

### MsgKit Version Compatibility

This project uses MsgKit 2.3.0 (or later) with the following API:

- `email.Attachments.Add(stream, fileName, renderingPosition, isInline, contentId)`
- Requires separate MemoryStream instances (cannot reuse closed streams)
- Properly handles `IsInline` property for embedded images

## Troubleshooting

### Images not displaying in Outlook

- ✅ Verify all image files exist in the `img/` directory
- ✅ Ensure `index.html` uses relative paths (not absolute)
- ✅ Check console output for "Attaching:" messages confirming image embedding

### Docker volume issues

If changes to code don't reflect:

```bash
docker compose down
docker compose up --build
```

### "Cannot access a closed Stream" error

This is handled correctly in the current version. The code:

1. Decodes content to byte array first
2. Creates a new MemoryStream from the byte array
3. Passes the new stream to `email.Attachments.Add()`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [MsgKit](https://github.com/Sicos1977/MsgKit) for MSG/OFT generation
- Uses [MimeKit](https://github.com/jstedfast/MimeKit) for MIME parsing
- HTML parsing powered by [BeautifulSoup4](https://www.crummy.com/software/BeautifulSoup/)
