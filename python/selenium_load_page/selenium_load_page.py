#!/usr/bin/python
##-------------------------------------------------------------------
##
## File : selenium_load_page.py
## Author : 
## Description :
##    Test page loading with selenium: slow load, severe 
##              errors when launching network requests, and save screenshots as images.
##
## More reading: https://www.dennyzhang.com/selenium_docker
##
## Sample:
##   - Test page load: basic test
##        python ./selenium_load_page.py --page_url https://www.dennyzhang.com
##
##   - Test page load: if it takes more than 5 seconds, fail the test. Default timeout is 10 seconds
##        python ./selenium_load_page.py --page_url https://www.dennyzhang.com --max_load_seconds 5
##
##   - Test page load: after page loading, save screenshot
##        python ./selenium_load_page.py --page_url https://www.dennyzhang.com --should_save_screenshot true
##
## --
## Created : <2017-02-24>
## Updated: Time-stamp: <2017-04-24 13:12:44>
##-------------------------------------------------------------------
import sys, argparse

from datetime import datetime
import time
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

sleep_delay = 5
IGNORE_ERROR_LIST = ["favicon.ico"]

def load_page(page_url, remote_server, max_load_seconds, \
              screenshot_dir, should_save_screenshot):
    load_timeout = 120 # seconds
    is_ok = True
    driver = webdriver.Remote(command_executor = remote_server, \
                              desired_capabilities=DesiredCapabilities.CHROME)

    try:
        # Cleanup cache
        driver.delete_all_cookies()

        # driver.set_page_load_timeout(load_timeout)

        print("Open page: %s" % (page_url))
        start_clock = time.clock()

        end_clock = time.clock()
        elapsed_seconds = ((end_clock - start_clock) * 1000 - sleep_delay)
        if elapsed_seconds > max_load_seconds:
            print("ERROR: page load is too slow. It took %s seconds, more than %d seconds." \
                  % ("{:.2f}".format(elapsed_seconds), max_load_seconds))
            is_ok = False
        else:
            print("Page load took: %s seconds." % ("{:.2f}".format(elapsed_seconds)))

        all_warnings = driver.get_log('browser')
        critical_errors = []

        for warning in all_warnings:
            if warning['level'] == 'SEVERE':
                has_error = True
                for ignore_err in IGNORE_ERROR_LIST:
                    if ignore_err in warning['message']:
                        has_error = False
                        break
                if has_error is True:
                    critical_errors.append(warning)

        if len(critical_errors) != 0:
            print("ERROR: severe errors have happened when loading the page. Details:\n\t%s" \
                  % "\n\t".join([str(error) for error in critical_errors]))
            is_ok = False

        save_screenshot_filepath = "%s/%s-%s.png" % \
                                   (screenshot_dir, datetime.now().strftime('%Y-%m-%d_%H%M%S'), \
                                    page_url.rstrip("/").split("/")[-1])
        if should_save_screenshot is True:
            print("Save screenshot to %s" % (save_screenshot_filepath))
            driver.get_screenshot_as_file(save_screenshot_filepath)
    except Exception as e:
        print("ERROR: get exception: %s" % (e))
        is_ok = False        
    finally:
        driver.close()
        # quit session
        driver.quit()

    return is_ok

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--page_url', required=True, help="URL for the web page to test", type=str)
    parser.add_argument('--remote_server', required=False, default="http://127.0.0.1:4444/wd/hub", \
                        help="Remote selenium server to run the test", type=str)
    parser.add_argument('--max_load_seconds', required=False, default=10, \
                        help="If page load takes too long, quit the test", type=int)
    parser.add_argument('--should_save_screenshot', required=False, dest='should_save_screenshot', \
                        action='store_true', default=True, \
                        help="Once enabled, selenium will save the page as screenshot in the selenium server", \
                        type=bool)
    parser.add_argument('--screenshot_dir', required=False, default="/tmp/screenshot""", \
                        help="Where to save screenshots", type=str)

    l = parser.parse_args()
    page_url = l.page_url
    remote_server = l.remote_server
    max_load_seconds = l.max_load_seconds
    should_save_screenshot = l.should_save_screenshot
    screenshot_dir = l.screenshot_dir

    # Run page loading test
    is_ok = load_page(page_url, remote_server, max_load_seconds, \
                      screenshot_dir, should_save_screenshot)
    if is_ok is False:
        sys.exit(1)
## File : selenium_load_page.py ends
