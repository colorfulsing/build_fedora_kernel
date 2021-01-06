FROM fedora:33
RUN dnf check-update -y; test $? -ne 1
RUN dnf upgrade -y
RUN dnf install koji rpmdevtools dnf-plugins-core bash -y
WORKDIR /root
COPY agesa.patch /root/agesa.patch
COPY acs-override-script-fedora33.sh /root/acs-override-script-fedora33.sh
COPY buildkernel.sh /root/buildkernel.sh
RUN chmod +x buildkernel.sh
RUN mkdir /rpms
VOLUME /rpms
ENTRYPOINT ["/root/buildkernel.sh"]
