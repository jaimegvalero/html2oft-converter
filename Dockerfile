FROM mcr.microsoft.com/dotnet/sdk:8.0

# 1. Install Python
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*
RUN pip3 install beautifulsoup4 --break-system-packages

# 2. PREPARE .NET ENVIRONMENT IN A SAFE FOLDER (/project)
WORKDIR /project
RUN dotnet new console -n ConversorOutlook --force
WORKDIR /project/ConversorOutlook

# Copy .csproj and restore
COPY ConversorOutlook.csproj .
RUN dotnet restore

# Copy source and build in Release mode
COPY Program.cs .
RUN dotnet build -c Release
RUN dotnet publish -c Release -o /app/dotnet

# 3. Return to /app so it is the starting directory when running
WORKDIR /app

# Copy Python and shell scripts
COPY generate_eml.py /app/
COPY process_all.sh /app/

CMD ["bash"]