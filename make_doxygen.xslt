<!-- Copyright (c) 2008 Niels Aan de Brugh

     Permission is hereby granted, free of charge, to any person
     obtaining a copy of this software and associated documentation
     files (the "Software"), to deal in the Software without
     restriction, including without limitation the rights to use,
     copy, modify, merge, publish, distribute, sublicense, and/or sell
     copies of the Software, and to permit persons to whom the
     Software is furnished to do so, subject to the following
     conditions:
     
     The above copyright notice and this permission notice shall be
     included in all copies or substantial portions of the Software.
     
     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
     OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
     HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
     WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
     FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
     OTHER DEALINGS IN THE SOFTWARE.
 -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="text" version="1.0" indent="no" standalone="yes"/>

    <!-- Parameters passed via the call to XSLT processor. -->

    <xsl:param name="line_nr"/>
    <!-- possible values for begin_tag: 1 makes /** ... */. 2 makes /*! ... */ -->
    <xsl:param name="begin_tag" select="1"/>
    <!-- possible values for item_prefix: 1 makes \brief. 2 makes @brief-->
    <xsl:param name="item_prefix" select="1"/>

    <!-- Some configuration in this file. -->

    <xsl:variable name="empty_field"><para>&lt;++&gt;</para></xsl:variable>
    <xsl:variable name="tag_prefix">\</xsl:variable>

    <!-- End of configuration section. -->

    <xsl:template match="/">
        <xsl:if test="count( doxygen/compounddef/sectiondef/memberdef/location[@line=$line_nr] ) = 0">
            <xsl:message terminate="true">Illegal offset.</xsl:message>
        </xsl:if>
        <xsl:for-each select="doxygen/compounddef/sectiondef/memberdef/location[@line=$line_nr]">
            <xsl:apply-templates select=".."/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="memberdef">
        <xsl:call-template name="open_tag"/>
        <xsl:choose>
            <xsl:when test="@kind='function'">
                <xsl:apply-templates select="." mode="function"/>
            </xsl:when>
        </xsl:choose>
        <xsl:call-template name="close_tag"/>
    </xsl:template>

    <!-- Function documentation -->

    <xsl:template match="memberdef" mode="function">
        <xsl:call-template name="open_line"/>

        <!-- brief description -->
        <xsl:call-template name="add_item">
            <xsl:with-param name="key">brief</xsl:with-param>
            <xsl:with-param name="long">
                <xsl:apply-templates select="briefdescription/para"/>
            </xsl:with-param>
        </xsl:call-template>

        <!-- detailed description -->
        <xsl:for-each select="detaileddescription/para">
            <xsl:variable name="this_param">
                <xsl:apply-templates select="."/>
            </xsl:variable>
            <xsl:if test="string-length( $this_param ) > 0">
                <xsl:call-template name="open_line"/>
                <xsl:value-of select="$this_param"/>
            </xsl:if>
        </xsl:for-each>

        <!-- template parameters -->
        <xsl:if test="count( templateparamlist/param ) > 0">
            <xsl:call-template name="open_line"/>
        </xsl:if>
        <xsl:for-each select="templateparamlist/param">
            <xsl:variable name="tparam_name" select="declname"/>
            <xsl:call-template name="add_item">
                <xsl:with-param name="key">tparam</xsl:with-param>
                <xsl:with-param name="short" select="$tparam_name"/>
                <xsl:with-param name="long">
                    <xsl:for-each select="../../detaileddescription/para/parameterlist[@kind='templateparam']/parameteritem/parameternamelist">
                        <xsl:if test="parametername=$tparam_name">
                            <xsl:apply-templates select="../parameterdescription/para"/><!-- assume single paragraph -->
                        </xsl:if>
                    </xsl:for-each>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>

        <!-- parameters -->
        <xsl:if test="count( param ) > 0">
            <xsl:call-template name="open_line"/>
        </xsl:if>
        <xsl:for-each select="param">
            <xsl:variable name="param_name" select="declname"/>
            <xsl:call-template name="add_item">
                <xsl:with-param name="key">param</xsl:with-param>
                <xsl:with-param name="short" select="$param_name"/>
                <xsl:with-param name="long">
                    <xsl:for-each select="../detaileddescription/para/parameterlist[@kind='param']/parameteritem/parameternamelist">
                        <xsl:if test="parametername=$param_name">
                            <xsl:apply-templates select="../parameterdescription/para"/><!-- assume single paragraph -->
                        </xsl:if>
                    </xsl:for-each>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>

        <xsl:if test="type != 'void'">
            <xsl:call-template name="open_line"/>
            <xsl:call-template name="add_item">
                <xsl:with-param name="key">return</xsl:with-param>
                <xsl:with-param name="long">
                    <xsl:apply-templates select="detaileddescription/para/simplesect[@kind='return']/para">
                        <xsl:with-param name="open_new_line" select="0"/>
                    </xsl:apply-templates>
                </xsl:with-param>
                <xsl:with-param name="open_new_line" select="0"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Formatting -->

    <xsl:template match="para">
        <xsl:param name="open_new_line" select="1"/>
        <xsl:param name="indent" select="0"/>

        <xsl:variable name="processing_list" select="count( itemizedlist | orderedlist ) > 0"/>
        <xsl:if test="count( child::parameterlist | child::simplesect ) = 0">
            <xsl:apply-templates select="bold | emphasis | para | itemizedlist | orderedlist | computeroutput | text()">
                <xsl:with-param name="indent" select="$indent"/>
            </xsl:apply-templates>
            <xsl:if test="$open_new_line and not( $processing_list )">
                <xsl:call-template name="open_line"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="text()">
        <xsl:if test="string(.) != '&#10;'">
            <xsl:value-of select="."/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="list">
        <xsl:param name="indent"/>
        <xsl:param name="bullet"/>
        <!-- force line-break if this is nested list. -->
        <xsl:if test="$indent > 0">
            <xsl:call-template name="open_line"/>
        </xsl:if>
        <xsl:for-each select="listitem">
            <xsl:call-template name="repeat-string">
                <xsl:with-param name="str"><xsl:text>  </xsl:text></xsl:with-param>
                <xsl:with-param name="cnt" select="$indent"/>
            </xsl:call-template>
            <xsl:value-of select="$bullet"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="para">
                <xsl:with-param name="indent" select="$indent + 1"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="itemizedlist">
        <xsl:param name="indent"/>
        <xsl:call-template name="list">
            <xsl:with-param name="indent" select="$indent"/>
            <xsl:with-param name="bullet"><xsl:text>-</xsl:text></xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="orderedlist">
        <xsl:param name="indent"/>
        <xsl:call-template name="list">
            <xsl:with-param name="indent" select="$indent"/>
            <xsl:with-param name="bullet"><xsl:text>-#</xsl:text></xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="bold">
        <xsl:text>&lt;b&gt;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&lt;/b&gt;</xsl:text>
    </xsl:template>

    <xsl:template match="emphasis">
        <xsl:text>&lt;i&gt;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&lt;/i&gt;</xsl:text>
    </xsl:template>

    <xsl:template match="computeroutput">
        <xsl:text>&lt;tt&gt;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&lt;/tt&gt;</xsl:text>
    </xsl:template>

    <!-- Tag generation -->

    <xsl:template name="open_tag">
        <xsl:choose>
            <xsl:when test="$begin_tag = 1">
                <xsl:text>/**</xsl:text>
            </xsl:when>
            <xsl:when test="$begin_tag = 2">
                <xsl:text>/*!</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="open_line">
        <xsl:text>&#10; * </xsl:text>
    </xsl:template>

    <xsl:template name="close_tag">
        <xsl:text>&#10; */&#10;</xsl:text>
    </xsl:template>

    <xsl:template name="item_prefix">
        <xsl:choose>
            <xsl:when test="$item_prefix=1"><xsl:text>\</xsl:text></xsl:when>
            <xsl:when test="$item_prefix=2"><xsl:text>@</xsl:text></xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="add_item">
        <xsl:param name="key"/>
        <xsl:param name="short"/>
        <xsl:param name="long"><xsl:value-of select="$empty_field"/></xsl:param>
        <xsl:param name="open_new_line" select="1"/>
        <xsl:call-template name="item_prefix"/>
        <xsl:value-of select="$key"/>
        <xsl:text> </xsl:text>
        <xsl:if test="string-length( $short ) > 0">
            <xsl:value-of select="$short"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="string-length( $long ) > 0">
                <xsl:value-of select="$long"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$empty_field"/>
                <xsl:if test="$open_new_line">
                    <xsl:call-template name="open_line"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Utility -->

    <!-- From ASPN, by Mats Kindahl. The following code is in the public domain. -->
    <!-- Repeat the string 'str' 'cnt' times -->
    <xsl:template name="repeat-string">
        <xsl:param name="str"/><!-- The string to repeat -->
        <xsl:param name="cnt"/><!-- The number of times to repeat the string -->
        <xsl:param name="pfx"/><!-- The prefix to add to the string -->
        <xsl:choose>
            <xsl:when test="$cnt = 0">
                <xsl:value-of select="$pfx"/>
            </xsl:when>
            <xsl:when test="$cnt mod 2 = 1">
                <xsl:call-template name="repeat-string">
                    <xsl:with-param name="str" select="concat($str,$str)"/>
                    <xsl:with-param name="cnt" select="($cnt - 1) div 2"/>
                    <xsl:with-param name="pfx" select="concat($pfx,$str)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="repeat-string">
                    <xsl:with-param name="str" select="concat($str,$str)"/>
                    <xsl:with-param name="cnt" select="$cnt div 2"/>
                    <xsl:with-param name="pfx" select="$pfx"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
