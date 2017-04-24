# -*- coding: utf-8 -*-
#!/usr/bin/python
def load_page(page_url, save_screenshot_filepath = ''):
    import time
    from selenium import webdriver
    seconds_to_load = 0
    load_timeout = 300 # seconds

    # driver_path = "/Users/mac/Downloads/chromedriver"
    # driver = webdriver.Chrome(driver_path)
    driver = webdriver.Chrome()

    # cleanup cache
    driver.delete_all_cookies()

    # Clean cache
    driver.set_page_load_timeout(load_timeout)

    print "Open page: %s" % (page_url)
    start_clock = time.clock()
    p = driver.get(page_url)
    end_clock = time.clock()
    elapsed_seconds = ((end_clock - start_clock) * 1000)
    print "Page load took: %f seconds." % (elapsed_seconds)

    all_warnings = driver.get_log('browser')
    network_warnings = []
    javascript_warnings = []

    for warning in all_warnings:
        if warning['source'] == 'javascript':
            javascript_warnings.append(warning)
        if warning['source'] == 'network':
            network_warnings.append(warning)

    if len(network_warnings) != 0:
        print "ERROR: network issues are detected when loading the page. Details: %s" \
            % (network_warnings)

    if len(javascript_warnings) != 0:
        print "ERROR: javascript issues are detected when loading the page. Details: %s" \
            % (javascript_warnings)

    if save_screenshot_filepath != '':
        print "Save screenshot to %s" % (save_screenshot_filepath)
        driver.get_screenshot_as_file(save_screenshot_filepath)
    return elapsed_seconds, all_warnings

if __name__ == '__main__':
    # elapsed_seconds, all_warnings = load_page('http://doc.carol.ai', '/tmp/test.png')
    elapsed_seconds, all_warnings = load_page('http://www.dennyzhang.com', '/tmp/test.png')
