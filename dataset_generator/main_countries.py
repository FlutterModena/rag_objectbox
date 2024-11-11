import os
from os import path
import shutil
from tqdm import tqdm
import requests
import xml.etree.ElementTree as ET
import wikitextparser as wtp


SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
OUTPUT_DIR = path.join(SCRIPT_DIR, "data_countries")
NS = "{http://www.mediawiki.org/xml/export-0.11/}"

#shutil.rmtree(OUTPUT_DIR, ignore_errors=True)

try:
    os.mkdir(OUTPUT_DIR)
except:
    pass

def download_country_page(country_name: str):
    output_filename = path.join(OUTPUT_DIR, f"{country_name}.txt")
    if path.exists(output_filename):
        return
    
    url = f"https://en.wikipedia.org/wiki/Special:Export/{country_name.replace(" ", "_")}"
    response = requests.get(url)
    xml = response.text
    root = ET.fromstring(xml)
    
    child = root.find(f"{NS}page")
    #page_title = child.find(f"{NS}title").text
    page_content = child.find(f"{NS}revision").find(f"{NS}text").text
    
    parsed_page = wtp.parse(page_content)
    plain_page_content = ""
    for section in parsed_page.sections:
        plain_page_content += section.plain_text().strip() + "\n"
    
    with open(output_filename, "wt") as f:
        f.write(plain_page_content)
    

def download_countries_page():
    url = f"https://simple.wikipedia.org/wiki/Special:Export/List_of_countries"
    response = requests.get(url)
    xml = response.text
    root = ET.fromstring(xml)
    
    child = root.find(f"{NS}page")
    #page_title = child.find(f"{NS}title").text
    page_content = child.find(f"{NS}revision").find(f"{NS}text").text
    parsed_page = wtp.parse(page_content)
    
    countries = []
    for template in parsed_page.templates:
        if template.name == "flag":
            countries.append(template.arguments[0].value)
            
    for country in tqdm(countries):
        try:
            download_country_page(country)
        except Exception as e:
            print(f"[WARN ] Country page not found for: {country}\n{e}") 
    
def _main():
    download_countries_page()
    
if __name__ == "__main__":
    _main()
