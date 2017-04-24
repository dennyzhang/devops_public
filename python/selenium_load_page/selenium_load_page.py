# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
##
## File : selenium_load_page.py
## Author : 
## Description :
##    Test page loading with selenium: slow load, severe 
##              errors when launching network requests, and save screenshots as images.
## Sample:
##   - Test page load: basic test
##        python ./selenium_load_page.py --page_url "http://www.dennyzhang.com"
##
##   - Test page load: if it takes more than 5 seconds, fail the test
##        python ./selenium_load_page.py --page_url "http://www.dennyzhang.com" --max_load_seconds 5
##
##   - Test page load: after page loading, save screenshot
##        python ./selenium_load_page.py --page_url "http://www.dennyzhang.com" --should_save_screenshot true
##
## --
## Created : <2017-02-24>
## Updated: Time-stamp: <2017-04-24 13:12:44>
##-------------------------------------------------------------------
import argparse
def load_page(page_url, remote_server, should_save_screenshot):
    load_timeout = 60 # seconds
    screenshot_dir = "/tmp"

    import time
    from selenium import webdriver
    from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

    driver = webdriver.Remote(command_executor = remote_server, \
                              desired_capabilities=DesiredCapabilities.CHROME)

    # Cleanup cache
    driver.delete_all_cookies()

    driver.set_page_load_timeout(load_timeout)

    print "Open page: %s" % (page_url)
    start_clock = time.clock()
    p = driver.get(page_url)
    end_clock = time.clock()
    elapsed_seconds = ((end_clock - start_clock) * 1000)
    print "Page load took: %f seconds." % (elapsed_seconds)

    all_warnings = driver.get_log('browser')
    critical_errors = []

    print all_warnings
    for warning in all_warnings:
        if warning['level'] == 'SEVERE':
            critical_errors.append(warning)

    if len(all_warnings) != 0:
        print "ERROR: severe errors happen when loading the page. Details: %s" \
            % "\n".join(all_warnings)

    save_screenshot_filepath = "%s/%s" % (screenshot_dir, page_url.rstrip("/").split()[-1])
    if should_save_screenshot is True:
        print "Save screenshot to %s" % (save_screenshot_filepath)
        driver.get_screenshot_as_file(save_screenshot_filepath)
    return elapsed_seconds, all_warnings

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--page_url', required=True, help="URL for the web page to test", type=str)
    parser.add_argument('--remote_server', required=False, default="http://127.0.0.1:32768/wd/hub", \
                        help="Remote selenium server to run the test", type=str)
    parser.add_argument('--max_load_seconds', required=False, default=20, \
                        help="If page load takes too long, quit the test", type=int)
    parser.add_argument('--should_save_screenshot', required=False, default=True, \
                        help="Once enabled, selenium will save the page as screenshot in the selenium server", \
                        type=bool)

    l = parser.parse_args()
    page_url = l.page_url
    remote_server = l.remote_server
    max_load_seconds = l.max_load_seconds
    should_save_screenshot = l.should_save_screenshot

    # Run page loading test
    elapsed_seconds, all_warnings = load_page(page_url, remote_server, should_save_screenshot)
## File : selenium_load_page.py ends
