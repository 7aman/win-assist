#!/usr/bin/python3
import os, sys
import json
from pathlib import Path
from getpass import getpass
import requests
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


def is_available(url):
	print(f"\nChecking {url}")
	try:
		if requests.get(url, timeout=1.0).status_code == 200:
			print("\tOK!")
			return True
	except Exception:
		pass
	print("\tNot Responding.")
	return False

def check_wifi(ifname, profile, iteration):
	if iteration:
		os.system(f"powershell .\\WiFi.ps1 {ifname} '{profile}' {True}")
	else:
		os.system(f"powershell .\\WiFi.ps1 {ifname} '{profile}' {False}")

def login(url, username, password):
	options = Options()
	# options.headless = True
	options.add_experimental_option('excludeSwitches', ['enable-logging'])
	browser = webdriver.Chrome(options=options)
	print("\nLogin headlessly via Chrome...")
	browser.get(url)
	if browser.find_elements_by_css_selector('input[value="OK"]'):
		elem = browser.find_elements_by_name('username') 
		elem[1].send_keys(username)
		elem = browser.find_elements_by_name('password') 
		elem[1].send_keys(password + Keys.RETURN)
	elif browser.find_elements_by_css_selector('input[value="log off"]'):
		print("\tAlready logged-in")
	browser.quit()

max_try = 10
iteration = 0
while iteration < max_try:
	if is_available("https://example.com"):
		break
	if is_available(url):
		login(url, username, password)
	else:
		check_wifi(ifname, profile, iteration)
	iteration += 1	
os.system("ping 8.8.8.8")
