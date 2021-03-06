<?xml version="1.0" encoding="utf-16"?>
<!--
 |
 | XSLT REC Compliant Version of IE5 Default Stylesheet
 |
 | Original version by Jonathan Marsh (jmarsh@xxxxxxxxxxxxx)
 | http://msdn.microsoft.com/xml/samples/defaultss/defaultss.xsl
 |
 | Conversion to XSLT 1.0 REC Syntax by Steve Muench (smuench@xxxxxxxxxx)
 | 
 | Further conversion by George Zabanah as follows:
 |
 | 24-Mar-2008 George Zabanah Fix to cdata function. 
 |                            Was supposed to check cdata != null.
 |                            Instead my check was xpath != null
 |                            Changed for consistency.
 | 14-Mar-2008 George Zabanah Modifications made to the XSLT stylesheet
 |                            to add a little spacing and change default colour
 |                            of namespace
 |                            Fixed xml Namespace rendering
 |                            Added CDATA handling using exslt regExp
 |                            Added XML Processing Instruction (if available)
 |                            Added handling for xmlns:*
 +-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                xmlns:regExp="http://exslt.org/regular-expressions"
                extension-element-prefixes="regExp msxsl">
  <xsl:param name="xmlinput"/>

  <msxsl:script language="JavaScript" implements-prefix="regExp">
    <![CDATA[
      /* BEGIN: code written by George Zabanah */
      var tdom;
      function getXmlProcessingInstruction(xml)
      {
	      tdom = new ActiveXObject("MSXML2.FreeThreadedDOMDocument");
        tdom.loadXML(xml);
        var pinode = tdom.selectSingleNode("/pi('xml')");
        if(pinode != null) 
          return '<? xml ' + pinode.text + ' ?>';
        else
        return "";
      }
      function removedom()
      {
        tdom = null;
        return "";
      }
      function cdataExists(xpath)
      {
        var cdata = tdom.selectSingleNode(xpath);
        return cdata != null;
        
      }
      function getNodeName(xpath)
      {
        return tdom.selectSingleNode(xpath).nodeName;
      }
      function getNodeValue(xpath)
      {
        return tdom.selectSingleNode(xpath).nodeValue;
      }
      function getCDATA(xpath)
      {
        var cdata = tdom.selectSingleNode(xpath);
        if(cdata != null) return cdata.text;
        else
        return "";
      }
      function xpathCount(xml,xpath)
      {
        var nsNode = tdom.selectNodes(xpath);
        if(nsNode == null || nsNode.length == null) return 0;
        return nsNode.length;
      }
      /* END: Code written by George Zabanah */
      /* BEGIN: EXSLT functions */
      function test(ctx, re, flags){
	      var ipString = "";
	      if (typeof(ctx) == "object"){
		      if (ctx.length){
			      for (var i=0; i < 1; i++){
				      var ctxN  = ctx.item(i);
				      if (ctxN.nodeType == 1){
					      ipString +=   _wander(ctxN);
				      }
				      if (ctxN.nodeType == 2){
					      ipString += ctxN.nodeValue;
				      }
			      }
		      }else{
			      return false;
		      }
	      }else{
		      ipString = ctx;
	      }
	      var oRe = new RegExp(re, flags);
	      return oRe.test(ipString);
      }
      function replace(ctx, re, flags, repStr){
	      var ipString = "";
	      if (typeof(ctx) == "object"){
		      if (ctx.length){
			      for (var i=0; i < 1; i++){
				      var ctxN  = ctx.item(i);
				      if (ctxN.nodeType == 1){
					      ipString +=   _wander(ctxN);
				      }
				      if (ctxN.nodeType == 2){
					      ipString += ctxN.nodeValue;
				      }
			      }
		      }else{
			      return "";
		      }
	      }else{
		      ipString = ctx;
	      }
	      var re = new RegExp(re, flags);
	      return ipString.replace(re, repStr);
      }
      function   _wander(ctx){
	      var retStr = "";
	      for (var i=0; i < ctx.childNodes.length; i++){
		      var ctxN = ctx.childNodes[i];
		      switch(ctxN.nodeType){
			      case 1:
				      retStr +=   _wander(ctxN);
				      break;
			      case 3:
				      retStr += ctxN.nodeValue;
				      break;
			      default:
				      break;
		      }
	      }
	      return retStr;
      }
      /* END: EXSLT functions */
  ]]>
  </msxsl:script>
  <xsl:output indent="no" method="html" />

  <xsl:template match="/">
    <HTML>
      <HEAD>
        <SCRIPT>
          <xsl:comment>
            <![CDATA[
                  function f(e){
                     if (e.className=="ci") {
                       if (e.children(0).innerText.indexOf("\n")>0) fix(e,"cb");
                     }
                     if (e.className=="di") {
                       if (e.children(0).innerText.indexOf("\n")>0) fix(e,"db");
                     } e.id="";
                  }
                  function fix(e,cl){
                    e.className=cl;
                    e.style.display="block";
                    j=e.parentElement.children(0);
                    j.className="c";
                    k=j.children(0);
                    k.style.visibility="visible";
                    k.href="#";
                  }
                  function ch(e) {
                    mark=e.children(0).children(0);
                    if (mark.innerText=="+") {
                      mark.innerText="-";
                      for (var i=1;i<e.children.length;i++) {
                        e.children(i).style.display="block";
                      }
                    }
                    else if (mark.innerText=="-") {
                      mark.innerText="+";
                      for (var i=1;i<e.children.length;i++) {
                        e.children(i).style.display="none";
                      }
                    }
                  }
                  function ch2(e) {
                    mark=e.children(0).children(0);
                    contents=e.children(1);
                    if (mark.innerText=="+") {
                      mark.innerText="-";
                      if (contents.className=="db"||contents.className=="cb") {
                        contents.style.display="block";
                      }
                      else {
                        contents.style.display="inline";
                      }
                    }
                    else if (mark.innerText=="-") {
                      mark.innerText="+";
                      contents.style.display="none";
                    }
                  }
                  function cl() {
                    e=window.event.srcElement;
                    if (e.className!="c") {
                      e=e.parentElement;
                      if (e.className!="c") {
                        return;
                      }
                    }
                    e=e.parentElement;
                    if (e.className=="e") {
                      ch(e);
                    }
                    if (e.className=="k") {
                      ch2(e);
                    }
                  }
                  function ex(){}
                  function h(){window.status=" ";}
                  document.onclick=cl;
              ]]>
          </xsl:comment>
        </SCRIPT>
        <STYLE>
          BODY {font:x-small 'Verdana'; margin-right:1.5em}
          .c  {cursor:hand}
          .b  {color:red; font-family:'Courier New'; font-weight:bold;
          text-decoration:none}
          .e  {margin-left:1em; text-indent:-1em; margin-right:1em}
          .k  {margin-left:1em; text-indent:-1em; margin-right:1em}
          .t  {color:#990000}
          .xt {color:#990099}
          .ns {color:red}
          .dt {color:green}
          .m  {color:blue}
          .tx {font-weight:bold}
          .db {text-indent:0px; margin-left:1em; margin-top:0px;
          margin-bottom:0px;padding-left:.3em;
          border-left:1px solid #CCCCCC; font:small Courier}
          .di {font:small Courier}
          .d  {color:blue}
          .pi {color:blue}
          .cb {text-indent:0px; margin-left:1em; margin-top:0px;
          margin-bottom:0px;padding-left:.3em; font:small Courier;
          color:#888888}
          .ci {font:small Courier; color:#888888}
          PRE {margin:0px; display:inline}
        </STYLE>
      </HEAD>
      <BODY class="st">
        <xsl:call-template name="xmlprocessinginstruction"/>
        <xsl:apply-templates/>
        <xsl:value-of select="regExp:removedom()"/>
      </BODY>
    </HTML>
  </xsl:template>

  <xsl:template match="processing-instruction()">
    <DIV class="e">
      <SPAN class="b">
        <xsl:call-template name="entity-ref">
          <xsl:with-param name="name">nbsp</xsl:with-param>
        </xsl:call-template>
      </SPAN>
      <SPAN class="m">
        <xsl:text>&lt;?</xsl:text>
      </SPAN>
      <SPAN class="pi">
        <xsl:value-of select="name(.)"/>
        <xsl:value-of select="."/>
      </SPAN>
      <SPAN class="m">
        <xsl:text>?></xsl:text>
      </SPAN>
    </DIV>
  </xsl:template>

  <!-- added handling for xml namespace - GZ -->
  <xsl:template match="@*[starts-with(name(),'xml:')]">
    <xsl:text> </xsl:text>
    <SPAN class="ns">
      <xsl:value-of select="name()" />
    </SPAN>
    <SPAN class="m">="</SPAN>
    <B class="ns">
      <xsl:value-of select="."/>
    </B>
    <SPAN class="m">"</SPAN>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:text> </xsl:text>
    <SPAN>
      <xsl:attribute name="class">
        <xsl:if test="xsl:*/@*">
          <xsl:text>x</xsl:text>
        </xsl:if>
        <xsl:text>t</xsl:text>
      </xsl:attribute>
      <xsl:value-of select="name(.)"/>
    </SPAN>
    <SPAN class="m">="</SPAN>
    <B>
      <xsl:value-of select="."/>
    </B>
    <SPAN class="m">"</SPAN>
  </xsl:template>

  <xsl:template match="text()">
    <DIV class="e">
      <SPAN class="b"> </SPAN>
      <SPAN class="tx">
        <xsl:value-of select="."/>
      </SPAN>
    </DIV>
  </xsl:template>

  <xsl:template match="comment()">
    <DIV class="k">
      <SPAN>
        <A STYLE="visibility:hidden" class="b" onclick="return false" 
           onfocus="h()">-</A>
        <xsl:text> </xsl:text>
        <SPAN class="m">
          <xsl:text>&lt;!--</xsl:text>
        </SPAN>
      </SPAN>
      <SPAN class="ci" id="clean">
        <PRE>
          <xsl:value-of select="."/>
        </PRE>
      </SPAN>
      <SPAN class="b">
        <xsl:call-template name="entity-ref">
          <xsl:with-param name="name">nbsp</xsl:with-param>
        </xsl:call-template>
      </SPAN>
      <SPAN class="m">
        <xsl:text>--></xsl:text>
      </SPAN>
      <SCRIPT>f(clean);</SCRIPT>
    </DIV>
  </xsl:template>

  <!-- added xmlnsProcessor call - GZ -->
  <xsl:template match="*">
    <DIV class="e">
      <DIV STYLE="margin-left:1em;text-indent:-2em">
        <SPAN class="b">
          <xsl:call-template name="entity-ref">
            <xsl:with-param name="name">nbsp</xsl:with-param>
          </xsl:call-template>
        </SPAN>
        <SPAN class="m">&lt;</SPAN>
        <SPAN>
          <xsl:attribute name="class">
            <xsl:if test="xsl:*">
              <xsl:text>x</xsl:text>
            </xsl:if>
            <xsl:text>t</xsl:text>
          </xsl:attribute>
          <xsl:value-of select="name(.)"/>
        </SPAN>
        <xsl:call-template name="xmlnsProcessor"/>
        <xsl:apply-templates select="@*"/>
        <SPAN class="m">
          <xsl:text>/></xsl:text>
        </SPAN>
      </DIV>
    </DIV>
  </xsl:template>

  <!-- added xmlnsProcessr call - GZ -->
  <xsl:template match="*[node()]">
    <DIV class="e">
      <DIV class="c">
        <A class="b" href="#" onclick="return false" onfocus="h()">-</A>
        <xsl:text> </xsl:text>
        <SPAN class="m">&lt;</SPAN>
        <SPAN>
          <xsl:attribute name="class">
            <xsl:if test="xsl:*">
              <xsl:text>x</xsl:text>
            </xsl:if>
            <xsl:text>t</xsl:text>
          </xsl:attribute>
          <xsl:value-of select="name(.)"/>
        </SPAN>
        <xsl:call-template name="xmlnsProcessor"/>
        <xsl:apply-templates select="@*"/>
        <SPAN class="m">
          <xsl:text>></xsl:text>
        </SPAN>
      </DIV>
      <DIV>
        <xsl:apply-templates/>
        <DIV>
          <SPAN class="b">
            <xsl:call-template name="entity-ref">
              <xsl:with-param name="name">nbsp</xsl:with-param>
            </xsl:call-template>
          </SPAN>
          <xsl:text> </xsl:text>
          <SPAN class="m">
            <xsl:text>&lt;/</xsl:text>
          </SPAN>
          <SPAN>
            <xsl:attribute name="class">
              <xsl:if test="xsl:*">
                <xsl:text>x</xsl:text>
              </xsl:if>
              <xsl:text>t</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="name(.)"/>
          </SPAN>
          <SPAN class="m">
            <xsl:text>></xsl:text>
          </SPAN>
        </DIV>
      </DIV>
    </DIV>
  </xsl:template>

  <!-- Added cdata handling and xmlnsProcessor call - GZ -->
  <xsl:template match="*[text() and not (comment() or processing-instruction())]">
    <xsl:variable name="nodeName" select="name()"/>
    <xsl:variable name="cdataPath" select="concat('//',$nodeName,'[',count(preceding::node()[name() = $nodeName]),']/cdata()')"/>
    <xsl:variable name="cdataExists" select="regExp:cdataExists($cdataPath)" />
    <xsl:choose>
      <xsl:when test="$cdataExists">
        <DIV class="e">
          <DIV STYLE="margin-left:1em;text-indent:-2em" class="c">
            <A class="b" href="#" onclick="return false" onfocus="h()">-</A>
            <xsl:text> </xsl:text>
            <SPAN class="m">
              <xsl:text>&lt;</xsl:text>
            </SPAN>
            <SPAN>
              <xsl:attribute name="class">
                <xsl:if test="xsl:*">
                  <xsl:text>x</xsl:text>
                </xsl:if>
                <xsl:text>t</xsl:text>
              </xsl:attribute>
              <xsl:value-of select="name(.)"/>
            </SPAN>
            <xsl:call-template name="xmlnsProcessor"/>
            <xsl:apply-templates select="@*"/>
            <SPAN class="m">
              <xsl:text>></xsl:text>
            </SPAN>
          </DIV>
          <DIV>
            <SPAN>
              <DIV class="k">
                <SPAN>
                  <A class="b" onclick="return false" onfocus="h()"
                  STYLE="visibility:hidden">-</A>
                  <SPAN class="m">&lt;![CDATA[</SPAN>
                </SPAN>
                <SPAN id="clean" class="di">
                  <PRE>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="regExp:getCDATA($cdataPath)"/>
                  </PRE>
                </SPAN>
                <SPAN class="b">
                  &#160;
                </SPAN>
                <SPAN class="m">]]&gt;</SPAN>
                <SCRIPT>f(clean);</SCRIPT>
              </DIV>
              <SPAN class="b">
                <xsl:call-template name="entity-ref">
                  <xsl:with-param name="name">nbsp</xsl:with-param>
                </xsl:call-template>
              </SPAN>
              <xsl:text> </xsl:text>
            </SPAN>
            <SPAN class="m">&lt;/</SPAN>
            <SPAN>
              <xsl:attribute name="class">
                <xsl:if test="xsl:*">
                  <xsl:text>x</xsl:text>
                </xsl:if>
                <xsl:text>t</xsl:text>
              </xsl:attribute>
              <xsl:value-of select="name(.)"/>
            </SPAN>
            <SPAN class="m">
              <xsl:text>></xsl:text>
            </SPAN>
          </DIV>
        </DIV>
      </xsl:when>
      <xsl:otherwise>
        <DIV class="e">
          <DIV STYLE="margin-left:1em;text-indent:-2em">
            <SPAN class="b">
              <xsl:call-template name="entity-ref">
                <xsl:with-param name="name">nbsp</xsl:with-param>
              </xsl:call-template>
            </SPAN>
            <xsl:text> </xsl:text>
            <SPAN class="m">
              <xsl:text>&lt;</xsl:text>
            </SPAN>
            <SPAN>
              <xsl:attribute name="class">
                <xsl:if test="xsl:*">
                  <xsl:text>x</xsl:text>
                </xsl:if>
                <xsl:text>t</xsl:text>
              </xsl:attribute>
              <xsl:value-of select="name(.)"/>
            </SPAN>
            <xsl:call-template name="xmlnsProcessor"/>
            <xsl:apply-templates select="@*"/>
            <SPAN class="m">
              <xsl:text>></xsl:text>
            </SPAN>
            <SPAN class="tx">
              <xsl:value-of select="."/>
            </SPAN>
            <SPAN class="m">&lt;/</SPAN>
            <SPAN>
              <xsl:attribute name="class">
                <xsl:if test="xsl:*">
                  <xsl:text>x</xsl:text>
                </xsl:if>
                <xsl:text>t</xsl:text>
              </xsl:attribute>
              <xsl:value-of select="name(.)"/>
            </SPAN>
            <SPAN class="m">
              <xsl:text>></xsl:text>
            </SPAN>
          </DIV>
        </DIV>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- added xmlnsProcessor call - GZ -->
  <xsl:template match="*[*]" priority="20">
    <DIV class="e">
      <DIV STYLE="margin-left:1em;text-indent:-2em" class="c">
        <A class="b" href="#" onclick="return false" onfocus="h()">-</A>
        <xsl:text> </xsl:text>
        <SPAN class="m">&lt;</SPAN>
        <SPAN>
          <xsl:attribute name="class">
            <xsl:if test="xsl:*">
              <xsl:text>x</xsl:text>
            </xsl:if>
            <xsl:text>t</xsl:text>
          </xsl:attribute>
          <xsl:value-of select="name(.)"/>
        </SPAN>
        <xsl:call-template name="xmlnsProcessor"/>
        <xsl:apply-templates select="@*"/>
        <SPAN class="m">
          <xsl:text>></xsl:text>
        </SPAN>
      </DIV>
      <DIV>
        <xsl:apply-templates/>
        <DIV>
          <SPAN class="b">
            <xsl:call-template name="entity-ref">
              <xsl:with-param name="name">nbsp</xsl:with-param>
            </xsl:call-template>
          </SPAN>
          <xsl:text> </xsl:text>
          <SPAN class="m">
            <xsl:text>&lt;/</xsl:text>
          </SPAN>
          <SPAN>
            <xsl:attribute name="class">
              <xsl:if test="xsl:*">
                <xsl:text>x</xsl:text>
              </xsl:if>
              <xsl:text>t</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="name(.)"/>
          </SPAN>
          <SPAN class="m">
            <xsl:text>></xsl:text>
          </SPAN>
        </DIV>
      </DIV>
    </DIV>
  </xsl:template>

  <!-- Namespace selector - GZ -->
  <xsl:template name="xmlnsSelector">
    <xsl:param name="xPath"/>
    <xsl:param name="xpathCount"/>
    <xsl:param name="startNode"/>

    <xsl:text> </xsl:text>
    <SPAN class="ns">
      <xsl:value-of select="regExp:getNodeName(concat($xPath,'[',$startNode,']'))" />
    </SPAN>
    <SPAN class="m">="</SPAN>
    <B class="ns">
      <xsl:value-of select="regExp:getNodeValue(concat($xPath,'[',$startNode,']'))"/>
    </B>
    <SPAN class="m">"</SPAN>
    <xsl:if test="$xpathCount - 1 > $startNode">
      <xsl:call-template name="xmlnsSelector">
        <xsl:with-param name="xPath" select="$xPath"/>
        <xsl:with-param name="xpathCount" select="$xpathCount"/>
        <xsl:with-param name="startNode" select="$startNode + 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Namespace processor - GZ -->
  <xsl:template name="xmlnsProcessor">
    <xsl:param name="node" select="."/>
    <xsl:variable name="level">
      <xsl:call-template name="getXPath">
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="nodeName" select="name($node)" />
    <xsl:variable name="xpathCount" select="regExp:xpathCount($xmlinput,concat($level,'[',count(preceding::node()[name() = $nodeName]),']/@xmlns:*'))"/>
    <xsl:if test="$xpathCount > 0">
      <xsl:call-template name="xmlnsSelector">
        <xsl:with-param name="xPath" select="concat($level,'[',count(preceding::node()[name() = $nodeName]),']/@xmlns:*')" />
        <xsl:with-param name="xpathCount" select="$xpathCount"/>
        <xsl:with-param name="startNode" select="'0'"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- handling for xml declaration - GZ -->
  <xsl:template name="xmlprocessinginstruction">
    <xsl:variable name="xmlprocdec" select="regExp:getXmlProcessingInstruction($xmlinput)"/>
    <xsl:if test="$xmlprocdec != ''">
      <DIV class="e">
        <SPAN class="b">
          <xsl:call-template name="entity-ref">
            <xsl:with-param name="name">nbsp</xsl:with-param>
          </xsl:call-template>
        </SPAN>
        <xsl:text> </xsl:text>
        <SPAN class="pi">
          <xsl:value-of select="$xmlprocdec"/>
        </SPAN>
      </DIV>
    </xsl:if>
  </xsl:template>

  <!-- recursive function to get Xpath for current node - GZ -->
  <xsl:template name="getXPath">
    <xsl:param name="node" select="."/>
    <xsl:if test="$node/parent::node()">
      <xsl:call-template name="getXPath">
        <xsl:with-param  name="node" select="$node/parent::node()"/>
      </xsl:call-template>
      <xsl:value-of select="concat('/',name($node))"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="entity-ref">
    <xsl:param name="name"/>
    <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
    <xsl:value-of select="$name"/>
    <xsl:text>;</xsl:text>
  </xsl:template>

</xsl:stylesheet>