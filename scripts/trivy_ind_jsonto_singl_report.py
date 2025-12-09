import os
import json
import pandas as pd

# Define the root directory to search for JSON files
root_dir = "/home/ubuntu/abhi/new/trivy-reports"

# Initialize a list to hold the extracted data
data = []

# Walk through the directory structure
for subdir, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".json"):
            file_path = os.path.join(subdir, file)
            folder_name = os.path.basename(subdir)
            
            try:
                with open(file_path, 'r') as f:
                    content = json.load(f)
                    
                    # Extract general metadata
                    artifact_name = content.get('ArtifactName', 'Unknown')
                    
                    results = content.get('Results', [])
                    for result in results:
                        target = result.get('Target', 'Unknown')
                        vulnerabilities = result.get('Vulnerabilities', [])
                        
                        if not vulnerabilities:
                            # If no vulnerabilities, you might check for Misconfigurations or Secrets if needed
                            # But user asked for "issues", usually implies vulnerabilities.
                            # We can log "No Vulnerabilities Found" if we want a complete list of files scanned
                            # data.append({
                            #     "Folder": folder_name,
                            #     "File": file,
                            #     "Artifact": artifact_name,
                            #     "Target": target,
                            #     "IssueID": "No Vulnerabilities",
                            #     "Severity": "N/A"
                            # })
                            continue

                        for vuln in vulnerabilities:
                            vuln_id = vuln.get('VulnerabilityID', '')
                            pkg_name = vuln.get('PkgName', '')
                            installed_version = vuln.get('InstalledVersion', '')
                            fixed_version = vuln.get('FixedVersion', '')
                            severity = vuln.get('Severity', 'UNKNOWN')
                            title = vuln.get('Title', '')
                            description = vuln.get('Description', '')
                            
                            data.append({
                                "Folder": folder_name,
                                "File": file,
                                "Artifact": artifact_name,
                                "Target": target,
                                "Vulnerability ID": vuln_id,
                                "Severity": severity,
                                "Package Name": pkg_name,
                                "Installed Version": installed_version,
                                "Fixed Version": fixed_version,
                                "Title": title,
                                "Description": description
                            })
                            
            except Exception as e:
                print(f"Error processing file {file_path}: {e}")

# Function to remove illegal characters for Excel and truncate to limit
def sanitize_for_excel(value):
    if isinstance(value, str):
        # Remove characters that are not allowed in XML (Excel uses XML)
        # remove control characters except tab, newline, carriage return
        # Also truncate to 32000 characters to be safe (Excel limit is 32767)
        clean_value = "".join(ch for ch in value if (0x20 <= ord(ch) <= 0xD7FF) or 
                                             (0xE000 <= ord(ch) <= 0xFFFD) or 
                                             (0x10000 <= ord(ch) <= 0x10FFFF) or
                                             ch in ('\t', '\n', '\r'))
        
        # Prevent formula injection
        if clean_value.startswith(('=', '+', '-', '@')):
            clean_value = "'" + clean_value
            
        return clean_value[:32000]
    return value

# Create a DataFrame
df = pd.DataFrame(data)

# Apply sanitization to all columns
for col in df.columns:
    df[col] = df[col].apply(sanitize_for_excel)

# Define the output Excel file path
output_file = os.path.join(root_dir, "trivy_consolidated_report.xlsx")

# Write to Excel
try:
    # Use pandas to write, ensuring it uses openpyxl
    df.to_excel(output_file, index=False, engine='openpyxl')
    print(f"Successfully created Excel report with {len(df)} rows at {output_file}")
except Exception as e:
    print(f"Error writing Excel file: {e}")
