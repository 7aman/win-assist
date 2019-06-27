#!/usr/bin/python3
import os, sys
import json
from pathlib import Path
from getpass import getpass
import requests
from requests.adapters import HTTPAdapter
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options

def get_setting(json_file:Path):
	if json_file.exists():
		with open(json_file, "r") as jf:
			return json.load(jf)
	else:
		with open(json_file, "w") as jf:
			data = dict()
			data["url"] = input("url: ")
			data["username"] = input("username: ")
			data["password"] = getpass("password")
			data["ifname"] = input("interface name: ")
			data["profile"] = input("connection profile: ")
			json.dump(data,jf)
			return data
setting_file = Path().parent.joinpath(".", "credentials.json")
settings = get_setting(setting_file)
url = settings["url"]
username = settings["username"]
password = settings["password"]
ifname = settings["ifname"]
profile = settings["profile"]
s = requests.Session()
s.mount(url, HTTPAdapter(max_retries=1))

logged_in = False
while not logged_in:
	try:
		if requests.head("https://example.com").status_code == 200:
			result = "\tAlready logged in ..."
			logged_in = True
			break
		status = requests.get(url).status_code
		if status == 200:
			options = Options()
			options.headless = True
			# options.add_argument('log-level=3')
			# options.add_argument("--disable-logging")
			options.add_experimental_option('excludeSwitches', ['enable-logging'])
			browser = webdriver.Chrome(options=options)
			print("\nOpenning login page headlessly by Chrome...")
			browser.get(url)
			if browser.find_elements_by_css_selector('input[value="log off"]'):
				result = "\tAlready logged in ..."
				logged_in = True
			elif browser.find_elements_by_css_selector('input[value="OK"]'):
				elem = browser.find_elements_by_name('username') 
				elem[1].send_keys(username)
				elem = browser.find_elements_by_name('password') 
				elem[1].send_keys(password + Keys.RETURN)
				result = "\tUser '" + username + "' successfully logged in."
				logged_in = True
			else:
				result = "\tSomething is wrong..."
			browser.quit()
		else:
			print(f"status code: {status}")
			result = "\tServer is not responding..."
	except Exception:
		result = "\tServer is not responding. Checking wifi"
		os.system(f"powershell .\WiFi.ps1 {ifname} '{profile}'")

	print()
	print("Result:")
	print(result)

print("\nPing Result:")
os.system("ping 8.8.8.8")

