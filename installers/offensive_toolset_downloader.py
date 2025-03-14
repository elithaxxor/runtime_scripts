import requests
from bs4 import BeautifulSoup
import subprocess
import os

try:
    # Fetch the webpage
    url = "https://inventory.raw.pm/tools.html"
    response = requests.get(url)
    response.raise_for_status()
    html_content = response.text

    # Parse HTML for all links
    soup = BeautifulSoup(html_content, 'html.parser')
    links = soup.find_all('a', href=True)

    # Filter for GitHub links
    github_links = []
    for link in links:
        href = link['href']
        if 'github.com' in href:
            github_links.append(href)

    # Check if no GitHub links were found
    if not github_links:
        print("Warning: No GitHub links found on the page.")

    # Append .git if not present
    processed_links = []
    for link in github_links:
        if not link.endswith('.git'):
            link += '.git'
        processed_links.append(link)

    # Write to file
    with open('github_links.txt', 'w') as file:
        for link in processed_links:
            file.write(link + '\n')

    # Create a directory for repositories
    repo_dir = 'repos'
    os.makedirs(repo_dir, exist_ok=True)

    # Clone the repositories
    print("Starting to clone GitHub repositories into 'repos/'...")
    for link in processed_links:
        try:
            subprocess.run(['git', 'clone', link], cwd=repo_dir, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"Successfully cloned {link}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to clone {link}: {e}")
        except FileNotFoundError:
            print("Error: 'git' command not found. Please ensure Git is installed.")
            break

    print("GitHub links have been saved to github_links.txt and cloning attempted.")

except requests.RequestException as e:
    print(f"Failed to fetch the webpage: {e}")
