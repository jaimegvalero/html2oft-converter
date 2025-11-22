using System;
using System.IO;
using System.Linq;
using MimeKit;
using MsgKit;
using MsgKit.Enums;

class Program
{
    static void Main(string[] args)
    {
        if (args.Length != 2)
        {
            Console.WriteLine("Usage: dotnet run <eml_file> <oft_file>");
            Console.WriteLine("Example: dotnet run /app/draft.eml /app/result.oft");
            return;
        }

        string inputFile = args[0];
        string outputFile = args[1];

        Console.WriteLine($"🔍 Looking for file at: {inputFile}");

        if (!File.Exists(inputFile))
        {
            Console.WriteLine($"❌ CRITICAL ERROR: Cannot find {inputFile}");
            return;
        }

        try
        {
            Console.WriteLine("📖 Reading EML and converting...");
            var mimeMessage = MimeMessage.Load(inputFile);

            var senderEmail = mimeMessage.From.Mailboxes.FirstOrDefault()?.Address ?? "newsletter@yourcompany.com";
            var senderName = mimeMessage.From.Mailboxes.FirstOrDefault()?.Name ?? "Your Company";
            var sender = new Sender(senderEmail, senderName);
            var subject = mimeMessage.Subject ?? "No Subject";

            // Set draft=true for Outlook Classic compatibility
            // This enables HTML encapsulation in RTF and sets MSGFLAG_UNSENT
            using (var email = new Email(sender, subject, draft: true))
            {
                email.BodyHtml = mimeMessage.HtmlBody;

                // Iterate all body parts (Attachments and Inline)
                foreach (var part in mimeMessage.BodyParts.OfType<MimePart>())
                {
                    // Ignore text/html body parts
                    if (part.ContentType.IsMimeType("text", "html") || part.ContentType.IsMimeType("text", "plain"))
                    {
                        continue;
                    }

                    // Decode content to byte array first
                    byte[] fileData;
                    using (var tempStream = new MemoryStream())
                    {
                        part.Content.DecodeTo(tempStream);
                        fileData = tempStream.ToArray();
                    }

                    // Create a new MemoryStream that MsgKit can use
                    var attachmentStream = new MemoryStream(fileData);

                    // Get file name
                    string fileName = part.FileName ?? "image.dat";

                    // Check if it's an inline attachment based on ContentDisposition and ContentId
                    bool isInline = !string.IsNullOrEmpty(part.ContentId) &&
                                   part.ContentDisposition != null &&
                                   part.ContentDisposition.Disposition.Equals("inline", StringComparison.OrdinalIgnoreCase);

                    if (isInline)
                    {
                        string contentId = part.ContentId.Trim('<', '>');
                        Console.WriteLine($"   📎 Inline Image: {fileName} (CID: {contentId})");
                        // Use Add method with parameters: stream, fileName, renderingPosition, isInline, contentId
                        email.Attachments.Add(attachmentStream, fileName, -1, true, contentId);
                    }
                    else
                    {
                        // Normal attachment (not inline)
                        Console.WriteLine($"   📎 Attachment: {fileName}");
                        email.Attachments.Add(attachmentStream, fileName);
                    }
                }

                email.Save(outputFile);
                Console.WriteLine($"✅ CONVERSION COMPLETED! File generated: {outputFile}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ .NET Exception: {ex.Message}");
            Console.WriteLine("Please check that all images referenced in your HTML exist.");
        }
    }
}