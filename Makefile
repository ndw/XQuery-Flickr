all: flickr.xqy

flickr.xqy: flickr.HEAD flickr.wsdl wsdl2xq.xsl
	saxon flickr.wsdl wsdl2xq.xsl ,flickr.xqy
	cat flickr.HEAD ,flickr.xqy > $@
	@rm -f ,flickr.xqy
