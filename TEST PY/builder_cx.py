from cx_Freeze import setup, Executable

base = None    

executables = [Executable("Hello.py", base=base)]

packages = ["idna"]
options = {
    'build_exe': {    
        'packages':packages,
    },    
}

setup(
    name = "hello",
    options = options,
    version = "0",
    description = 'Hello World',
    executables = executables
)