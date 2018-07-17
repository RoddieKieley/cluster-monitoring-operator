# origin-base is a base image we never ship. It forms a base layer shared by all images
# and thus minimizes aggregate disk usage. In production builds automation will rewrite
# this as openshift3/ose-base
FROM openshift/origin-base

# Install build tools and prepare environment.  In production builds, layers
# will be squashed after the build runs so there is no need to combine RUN
# statements, though Origin builds could still benefit from doing that.
#
ENV GOPATH /go
RUN mkdir $GOPATH
RUN yum install -y golang make

# Install the source in GOPATH on the image.
#
COPY . $GOPATH/src/github.com/openshift/cluster-monitoring-operator

# Perform the binary build.
#
RUN cd $GOPATH/src/github.com/openshift/cluster-monitoring-operator \
 && make build

# Move the binary to a standard location where it will run.
#
RUN cp $GOPATH/src/github.com/openshift/cluster-monitoring-operator/operator /usr/bin/
ENTRYPOINT ["/usr/bin/operator"]

# Delete the build tools and any other artifacts. Note that for production builds
# the go toolchain is supplied by go-toolset-7, so a different set of packages
# needs to be removed than in Origin. yum does not fail as long as at least one
# package listed is present.
#
RUN yum erase -y make golang 'go-toolset-*' openssl-devel \
 && yum clean all \
 && rm -rf $GOPATH

# This image doesn't need to run as root user.
USER 1001

# Apply labels as needed. ART build automation fills in others required for
# shipping, including component NVR (name-version-release) and image name. OSBS
# applies others at build time. So most required labels need not be in the source.
#
# io.k8s.display-name is required and is displayed in certain places in the
# console (someone correct this if that's no longer the case)
#
# io.k8s.description is equivalent to "description" and should be defined per
# image; otherwise the parent image's description is inherited which is
# confusing at best when examining images.
#
LABEL io.k8s.display-name="OpenShift cluster-monitoring-operator" \
      io.k8s.description="This is a component of OpenShift Container Platform and manages the lifecycle of the Prometheus based cluster monitoring stack." \
      maintainer="Frederic Branczyk <fbranczy@redhat.com>"

