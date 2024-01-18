# https://robocorp.com/docs/courses/build-a-robot/create-order-process
# https://robocorp.com/docs/courses/build-a-robot/create-zip-file
# https://robocorp.com/docs/libraries/rpa-framework

*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.Excel.Files
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Variables ***
${OUTPUT_DIR}    ${CURDIR}/output
${get orders}
${button-exist}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Sleep    2s   # Adding a short delay to ensure the page has loaded
    Fill the form
    
*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders file, read it as a table, and return the result
    Download    https://robotsparebinindustries.com/orders.csv    ${OUTPUT_DIR}/orders.csv    overwrite=True
    ${get orders} =    Read table from CSV   ${OUTPUT_DIR}/orders.csv
    Log    ${get orders}
    RETURN    ${get orders}

Close the annoying modal
    Click Button    class:btn-dark
    Log    ${get orders}

Enter orders
    [Arguments]    ${head}    ${body}    ${legs}    ${address}
    Log    ${head}
    Select From List By Value    name:head    ${head}
    Select Radio Button    body    ${body}
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${legs}
    Input Text    id:address    ${address}

Retry order button
    FOR    ${index}    IN RANGE    10
        Log    ${index}
        Wait Until Keyword Succeeds    3x    0.5sec    Click Button    id:order
        ${success}=    Does Page Contain Button    id:order-another
        Log    ${success}
        Exit For Loop If    ${success}
    END

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Capture Page Screenshot    ${Order number}.png

Store order receipt as PDF
    [Arguments]    ${Order number}
    ${results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${results_html}    ${OUTPUT_DIR}/receipts/${Order number}.pdf
    Take a screenshot of the robot    ${Order number}
    Open Pdf    ${OUTPUT_DIR}/receipts/${Order number}.pdf
    Add Watermark Image To Pdf    ${OUTPUT_DIR}/${Order number}.png    ${OUTPUT_DIR}/receipts/${Order number}.pdf
    Close Pdf    ${OUTPUT_DIR}/receipts/${Order number}.pdf


Loop and submit the orders
    [Arguments]    ${table}
    Log    ${table}
    FOR    ${item}    IN    @{table}
        Close the annoying modal
        Enter orders    ${item}[Head]    ${item}[Body]    ${item}[Legs]    ${item}[Address]
        Click Button    id:preview
        Wait Until Keyword Succeeds    10x    2sec    Click Button    id:order
        ${button-exist} =    Does Page Contain Button    id:order-another
        IF    ${button-exist} == $True
            Store order receipt as PDF    ${item}[Order number]
            Wait Until Keyword Succeeds    3x    1sec    Click Button    id:order-another
        ELSE
            Retry order button
            Store order receipt as PDF    ${item}[Order number]
            Wait Until Keyword Succeeds    3x    1sec    Click Button    id:order-another
        END
    END


Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}/receipts    ${OUTPUT_DIR}/receipts.zip

Fill the form
    ${get orders} =    Download the orders file, read it as a table, and return the result
    Log    ${get orders}
    Loop and submit the orders    ${get orders}
    Create a ZIP file of receipt PDF files

    