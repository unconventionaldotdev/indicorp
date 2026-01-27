# This file is part of Indicorp.
# Copyright (C) 2023 UNCONVENTIONAL

import pkgutil
from importlib import import_module

from indico.core.plugins import IndicoPlugin

from . import modules


class Distro(IndicoPlugin):
    """Indicorp

    An Indico distribution plugin exploring the limits of the plugin system.
    """  # noqa: D400 Plugin name comes from docstring and it should not contain a period

    def init(self):
        super().init()
        self._init_modules()

    def _init_modules(self):
        """Initialize all modules without having to import them manually."""
        for module_info in pkgutil.iter_modules(modules.__path__):
            import_module(f'{modules.__name__}.{module_info.name}')
