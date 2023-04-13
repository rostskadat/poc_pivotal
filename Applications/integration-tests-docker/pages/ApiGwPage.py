from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions

from .BasePage import BasePage, BasePageElement


class ThroughApigwResultElement(BasePageElement):
    locator = (By.ID, "through-apigw-result")


class ThroughWebappResultElement(BasePageElement):
    locator = (By.ID, "through-webapp-result")


class ApiGwPage(BasePage):

    through_apigw_result = ThroughApigwResultElement()
    through_webapp_result = ThroughWebappResultElement()

    def __init__(self,  *args):
        super().__init__(*args)
        self.wait.until(expected_conditions.title_contains('APIGW'))

    def click_home_link(self):
        self.driver.find_element(By.ID, "home-link").click()
