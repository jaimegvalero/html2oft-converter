FROM mcr.microsoft.com/dotnet/sdk:8.0

# 1. Install Python
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*
RUN pip3 install beautifulsoup4 --break-system-packages

# 2. Prepare .NET environment in a safe folder (/project)
WORKDIR /project
RUN dotnet new console -n ConversorOutlook --force
WORKDIR /project/ConversorOutlook
# Install MsgKit and MimeKit (will use the latest compatible versions)
RUN dotnet add package MsgKit
RUN dotnet add package MimeKit

# 3. Set working directory
WORKDIR /app

CMD ["bash"]