<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:wsdl="http://www.w3.org/ns/wsdl"
                xmlns:whttp="http://www.w3.org/ns/wsdl/http"
                xmlns:wsdlx="http://www.w3.org/ns/wsdl-extensions"
                xmlns:tns="http://wso2.org/repos/wso2/people/jonathan/flickr.wsdl"
                version="2.0">

<xsl:output method="text"/>

<xsl:template match="/">
  <xsl:apply-templates select="/wsdl:description/wsdl:types/xs:schema/xs:element"/>
</xsl:template>

<xsl:template match="xs:element[@name='rsp' or @name='err']"/>

<xsl:template match="xs:element">
  <xsl:text>declare function flickr:</xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text>(</xsl:text>
  <xsl:choose>
    <xsl:when test=".//xs:element"><xsl:text>&#10;</xsl:text></xsl:when>
    <xsl:otherwise><xsl:text>)&#10;</xsl:text></xsl:otherwise>
  </xsl:choose>
  <xsl:for-each select=".//xs:element">
    <xsl:text>    $</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text> as </xsl:text>
    <xsl:choose>
      <xsl:when test="starts-with(@type, 'xs:')">
        <xsl:value-of select="@type"/>
      </xsl:when>
      <xsl:otherwise>xs:string</xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@minOccurs=0">?</xsl:if>
    <xsl:choose>
      <xsl:when test="position() &lt; last()">,</xsl:when>
      <xsl:otherwise>)</xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>{&#10;</xsl:text>
  <xsl:text>  let $method := &lt;method xmlns="http://www.flickr.com/services/api/"&#10;</xsl:text>
  <xsl:if test=".//xs:extension[@base='authenticatedFlickrRequest']">
    <xsl:text>                         auth="true"&#10;</xsl:text>
  </xsl:if>
  <xsl:if test=".//xs:extension[@base='signedFlickrRequest']">
    <xsl:text>                         sig="true"&#10;</xsl:text>
  </xsl:if>
  <xsl:text>                         name="flickr.</xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text>"&gt;&#10;</xsl:text>

  <xsl:for-each select=".//xs:element">
    <xsl:text>                   </xsl:text>

    <xsl:if test="@minOccurs=0">
      <xsl:text>{ if (empty($</xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text>))&#10;                     then ()&#10;</xsl:text>
      <xsl:text>                       else </xsl:text>
    </xsl:if>

    <xsl:text>&lt;arg name="</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>"&gt;{$</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>}&lt;/arg&gt;</xsl:text>

    <xsl:if test="@minOccurs=0"> }</xsl:if>
    <xsl:text>&#10;</xsl:text>
  </xsl:for-each>

  <xsl:text>                 &lt;/method&gt;&#10;</xsl:text>
  <xsl:text>  return&#10;</xsl:text>
  <xsl:text>    flickr:_flickr($method)&#10;</xsl:text>
  <xsl:text>};&#10;&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
