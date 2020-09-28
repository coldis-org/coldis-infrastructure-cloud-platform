FROM amazon/aws-cli:2.0.22

# Installs jq and dig.
RUN yum update -y && \
	yum install -y jq bind-utils && \
    yum clean -y all && \
    rm -rf /var/cache/yum

# Copies the scripts.
RUN mkdir -p /opt/aws-script
COPY script /opt/aws-script
RUN ln -s /opt/aws-script/*.sh /usr/bin && \
	for f in /usr/bin/aws*.sh; \
	do \
		mv -- "$f" "${f%.sh}"; \
	done

# Entrypoint.
ENTRYPOINT [ "/bin/sh", "-c" ]