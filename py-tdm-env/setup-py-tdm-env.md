## Setting up the WF TDM Python Environment

**Step 1: Download WF TDM Python Environment**

The WF TDM Python Environment (py-tdm-env) can be downloaded [here](zipfolder-resources-file). Extract the contents of the zipped folder to a strategic location on your computer. We suggest extracting to the following location: `C:\Python\py-tdm-env`. You may need to create your own folder named `Python` before extracting. If you do not permission to extract to the suggested location, extract somewhere else that makes sense.


**Step 1: Open Visual Studio Code**

If you don't have Visual Studio Code, download it [here](https://code.visualstudio.com/download). Next, open the WF TDM model folder in Visual Studio. This can be done by right clicking on the folder in File Explorer, and selecting `Open with Code`. Alternatively, you can open Visual Studio and select `File/Open Folder` from the main selection options.

*You can use a different text editor, however we recommend the Visual Studio IDE platform.*

**Step 2: Download Python and Jupyter Extensions**

After open Visual Studio, ensure that the `Python` and `Jupyter` extensions are downloaded. You can do this by navigating to `Extensions` window or pressing `Ctrl+Shift+X`. Next search for `Python` and `Jupyter` extensions and download them. 

**Step 3: Refresh Visual Studio**

 - Press `Ctrl+Shift+P` to open the command prompt in Visual Studio. 
 - Type `Reload: Window` and select it. 
 - After reloading, close out Visual Studio and then reopen it. 
 - Open or create a Jupyter Notebook file (`.ipynb`).

**Step 4: Locate the Python Interpreter**

 - Press `Ctrl+Shift+P`
 - Type `Python: Select Interpreter`
 - Navigate to the `python.exe` path that exists within the model. `2_ModelScripts/_Python/py-tdm-env`.

**Step 5: Create a New Kernel Spec**

Open a terminal or command prompt and navigate to the folder containing the python interpreter. In Visual Studio, simply click `Terminal/New Terminal` from the main selection options.

Create a new kernel specification using the specific python interpreter. This tells Jupyter to use this interpreter when running notebooks.

```python
# Navigate to the directory containing the python interpreter
cd 2_ModelScripts/_Python/py-tdm-env

# Install kernelspec for future use of jupyter notebooks
./python -m ipykernel install --user --name=py-tdm-env --display-name "py-tdm-env"
```

After creating the new kernel spec, reload Visual Studio.

**Step 6: Select Kernel**

The new environment should be automatically selected . If its not automatically selected, select the newly created kernel from the kernel selection box (top-right corner) with `Select Kernel/Jupyter Kernel../py-tdm-env`. Alternatively, you may also select the Python environment from the kernel selection box (top-right corner) with `Select Kernel/Python Environments../py-tdm-env`. Both should allow you to run cells in a Jupyter Notebook file.

*Note: The `Select Kernel` option only shows when a Jupyter notebook file is open.*

**Troubleshooting**

A few basic troubleshooting ideas include:

 - Reloading the Visual Studio Window
 - Closing out of Visual Studio
 - Restarting your Computer

If you are still having trouble, feel free to reach out to Chris Day at WFRC (cday@wfrc.org) and he'd be happy to assist.