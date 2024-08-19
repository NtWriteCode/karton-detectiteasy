# hadolint global ignore=DL3008
FROM python:3-bookworm

# ----------------------------------------------------------------------------------------------------------------------------------------------------------------
# This a patched buildscript for Detect it Easy which I used to build manually,
# however I just found out how to install DIE without huge GUI dependencies,
# so I'm not using this anymore.
# Left as is for legacy reasons, who knows when will I need this later on
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------
# # Dependencies
# RUN apt update -qq && apt upgrade -y && \
#     apt install -y build-essential cmake wget tar libglib2.0-0 qtbase5-dev qtscript5-dev qttools5-dev-tools libqt5svg5-dev git qt5-qmake
#
#
# # DIE repository
# RUN git clone https://github.com/horsicq/DIE-engine.git && cd DIE-engine && git checkout 3.09 && git submodule update --init --recursive
#
#
# # Patch DIE not to build GUI & Lite mode
# WORKDIR /DIE-engine
# RUN sed -i -e '/add_subdirectory(gui_source)/ s/^/#/' \
#     -e '/add_subdirectory(lite_source)/ s/^/#/' \
#     -e '/install (TARGETS die LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})/ s/^/#/' \
#     -e '/install (TARGETS diel LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})/ s/^/#/' CMakeLists.txt
#
#
# # Build DIEc
# RUN mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j4
#
#
# # Make it available under /die/diec
# RUN mkdir /die && cd /die && cp /DIE-engine/build/release/diec . && \
#     cp -r /DIE-engine/Detect-It-Easy/db* . && \
#     cp -r /DIE-engine/XYara/yara_rules .
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -s https://api.github.com/repos/horsicq/DIE-engine/releases/latest | grep -oP '"browser_download_url":\s*"\K(http.*Debian_12_amd64\.deb)' | xargs wget -q -O die.deb && \
    apt-get update && \
    apt-get install --no-install-recommends -y libqt5core5a libqt5script5 && \
    dpkg --ignore-depends=libqt5svg5,libqt5gui5,libqt5widgets5,libqt5opengl5,libqt5scripttools5,libqt5sql5,libqt5network5,libqt5dbus5 -i die.deb && \
    rm die.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY karton-die.py .
CMD ["python3", "karton-die.py"]
