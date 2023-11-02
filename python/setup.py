from setuptools import setup
ver = open("../VERSION", "r").read()
ver.close()
setup(
    name = 'PyMeow',
    version = ver,
    packages = ['pyMeow'],
    url = 'https://github.com/qb-0/pyMeow',
    license = 'MIT',
    author = 'qb',
    author_email = '',
    include_package_data=True,
    description = 'Python Library for external Game Hacking'
)
