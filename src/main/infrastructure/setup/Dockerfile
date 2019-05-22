FROM mesosphere/aws-cli:1.14.5

# Installs jq.
RUN apk --update add jq && \
	rm -rf /var/lib/apt/lists/* && \
	rm /var/cache/apk/*

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