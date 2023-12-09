# This file is part of Indicorp.
# Copyright (C) 2023 UNCONVENTIONAL

from indico.core.plugins import IndicoPlugin


class Distro(IndicoPlugin):
    """Indicorp.

    An Indico distribution plugin exploring the limits of the plugin system.
    """

    def init(self):
        super().init()
