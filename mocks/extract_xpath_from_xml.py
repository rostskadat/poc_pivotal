#! /usr/bin/env python3
import os
import sys

from lxml import etree as ET

path = os.getcwd()
pom_xml = path + '/' + str(sys.argv[1])

parser = ET.XMLParser(remove_comments=False)
xml = ET.parse(pom_xml, parser=parser)

# Find the project's current version
version = xml.find("./{*}version")
groupId = xml.find("./{*}groupId")
packaging = xml.find("./{*}packaging")
artifactId = xml.find("./{*}artifactId")

print("POM_VERSION=" + version.text)
print("POM_GROUPID=" + groupId.text)
print("POM_PACKAGING=" + packaging.text)
print("POM_ARTIFACTID=" + artifactId.text)


version_parent = xml.find("./{*}parent/{*}version")
groupId_parent = xml.find("./{*}parent/{*}groupId")
artifactId_parent = xml.find("./{*}parent/{*}artifactId")
