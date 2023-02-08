#Build stage
FROM alpine:latest as build

#Update 
RUN apk update
RUN apk upgrade 
RUN apk add --no-cache linux-headers alpine-sdk cmake tcl openssl-dev zlib-dev

#Clone projects
WORKDIR /tmp
RUN git clone https://github.com/Haivision/srt.git srt
RUN git clone https://github.com/Edward-Wu/srt-live-server.git sls

#Compile SRT
WORKDIR /tmp/srt
RUN ./configure
RUN make
RUN make install

#Compile srt-live-server
WORKDIR /tmp/sls
RUN make

#Final stage
FROM alpine:latest
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64
RUN apk update
RUN apk upgrade
RUN apk add --no-cache openssl libstdc++
RUN adduser -D srt
RUN mkdir /etc/sls /logs
RUN chown srt /logs
    
#Copy libs
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /tmp/sls/bin/* /usr/local/bin/
COPY sls.conf /etc/sls/

#Define points
VOLUME /logs
EXPOSE 1935/udp
USER srt
WORKDIR /home/srt
ENTRYPOINT ["sls", "-c", "/etc/sls/sls.conf"]
