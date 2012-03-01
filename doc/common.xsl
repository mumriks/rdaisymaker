<?xml version="1.0" encoding="UTF-8"?>

<!--******************************
       DAISY XSL TRANSFORM

    Make an XSL capable browser
    understand DAISY markup.
****************************** -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/">

  <xsl:output method="html" indent="no"/>

  <!-- framing skippable -->
  <xsl:attribute-set name="skippableFramingStyle">
    <xsl:attribute name="style">
      border-style:solid;
      border-width:1px;
      border-color:rgb(200,200,250)
    </xsl:attribute>
  </xsl:attribute-set>

  <!--******************************
   DOCBOOK, HEAD, META, LINK, BOOK
  *******************************-->

  <!-- docbook translates to html -->
  <xsl:template match="dtb:dtbook">
    <html>
      <xsl:apply-templates/>
    </html>
  </xsl:template>

  <!-- head maps directly -->
  <xsl:template match="dtb:head">
    <xsl:element name="head">
      <xsl:if test="@profile">
        <xsl:attribute name="profile">
          <xsl:value-of select="@profile"/>
        </xsl:attribute>
      </xsl:if>

      <title>
        <xsl:value-of select="/dtb:dtbook/dtb:book/dtb:frontmatter/dtb:doctitle"/>
      </title>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- meta maps directly
       Include: content
       If applicable, include: http-equiv, name
       NOTE: meta contains no content so no apply-templates necessary -->
  <xsl:template match="dtb:meta">
    <xsl:element name="meta">
      <xsl:if test="@http-equiv">
        <xsl:attribute name="http-equiv">
          <xsl:value-of select="@http-equiv"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@name">
        <xsl:attribute name="name">
          <xsl:value-of select="@name"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="content">
        <xsl:value-of select="@content"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- link maps directly
       If aqpplicable, includes: charset, href, hreflang, media, rel, rev, type
       NOTE: link contains no content so no apply-templates necessary -->
  <xsl:template match="dtb:link">
    <xsl:element name="link">
      <xsl:if test="@charset">
        <xsl:attribute name="charset">
          <xsl:value-of select="@charset"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@href">
        <xsl:attribute name="href">
          <xsl:value-of select="@href"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@hreflang">
        <xsl:attribute name="hreflang">
          <xsl:value-of select="@hreflang"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@media">
        <xsl:attribute name="media">
          <xsl:value-of select="@media"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rel">
        <xsl:attribute name="rel">
          <xsl:value-of select="@rel"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rev">
        <xsl:attribute name="rev">
          <xsl:value-of select="@rev"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@type">
        <xsl:attribute name="type">
          <xsl:value-of select="@type"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-- book should be translated to body -->
  <xsl:template match="dtb:book">
    <body>
      <xsl:apply-templates/>
    </body>
  </xsl:template>


  <!--*******************************
  FRONTMATTER, BODYMATTER, REARMATTER
  ******************************* -->

  <!--frontmatter, bodymatter and rearmatter become divisions with appropriate class attributes-->

  <xsl:template match="dtb:frontmatter">
    <div class="frontmatter">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="dtb:bodymatter">
    <div class="bodymatter">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="dtb:rearmatter">
    <div class="rearmatter">
      <xsl:apply-templates/>
    </div>
  </xsl:template>


  <!--**************************
  DOCTITLE, DOCAUTHOR, COVERTITLE
  ***************************-->

  <!-- doctitle is h1 with class for styling -->
  <xsl:template match="dtb:doctitle">
    <h1 class="doctitle">
      <xsl:apply-templates/>
    </h1>
  </xsl:template>

  <!-- docauthor is p with class for styling -->
  <xsl:template match="dtb:docauthor">
    <p class="docauthor">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- covertitle is p with class for styling -->
  <xsl:template match="dtb:covertitle">
    <p class="covertitle">
      <xsl:apply-templates/>
    </p>
  </xsl:template>


  <!--***********************
             LEVELS
  ************************-->

  <!-- Levels map to div with class -->
  <xsl:template match="dtb:level | dtb:level1 | dtb:level2 | dtb:level3 | dtb:level4 | dtb:level5 | dtb:level6">
    <xsl:element name="div">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!--***********************
            HEADINGS
  ************************-->

  <!--h1...h6 map directly -->

  <xsl:template match="dtb:h1 | dtb:h2 | dtb:h3 | dtb:h4 | dtb:h5 | dtb:h6">
    <xsl:element name="{local-name(.)}">
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- hd as child of level converts to h1...h6 based on number of level ancestors
       If more than 6 ancestors then defaults to h6, flattening hierarchy beyond level 6 -->
  <xsl:template match="dtb:level/dtb:hd">
    <xsl:if test="@id">
      <xsl:attribute name="id">
        <xsl:value-of select="@id" />
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="@smilref">
      <xsl:attribute name="smilref">
        <xsl:value-of select="@smilref" />
      </xsl:attribute>
    </xsl:if>
    <xsl:variable name="levelDepth" select="count(ancestor-or-self::dtb:level)" />
    <xsl:choose>
      <xsl:when test="$levelDepth &lt;= 6">
        <xsl:element name="{concat('h',$levelDepth)}">
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="h6">
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--for all hd, including those passed 6 levels and those within items like list use paragraph with class -->
  <!-- for bridgehead use paragraph with class -->
  <xsl:template match="dtb:hd | dtb:bridgehead">
    <xsl:element name="p">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!--*************************
         PAGENUM, LINENUM
  ************************-->

  <!--Put the pagenum into a paragraph element if the parent is level or level1...level6 otherwise put it into a span
      Use the pagenum class for formatting -->
  <xsl:template match="dtb:pagenum">
    <xsl:choose>
      <xsl:when test="parent::dtb:level or parent::dtb:level1 or parent::dtb:level2 or parent::dtb:level3 or parent::dtb:level4 or parent::dtb:level5 or parent::dtb:level6">
        <xsl:element name="p">
          <xsl:element name="span" use-attribute-sets="skippableFramingStyle">
            <xsl:attribute name="class">
              <xsl:value-of select="local-name(.)" />
            </xsl:attribute>
            <xsl:if test="@id">
              <xsl:attribute name="id">
                <xsl:value-of select="@id" />
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="@smilref">
              <xsl:attribute name="smilref">
                <xsl:value-of select="@smilref" />
              </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates />
          </xsl:element>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="span" use-attribute-sets="skippableFramingStyle">
          <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
          </xsl:attribute>
          <xsl:if test="@id">
            <xsl:attribute name="id">
              <xsl:value-of select="@id" />
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@smilref">
            <xsl:attribute name="smilref">
              <xsl:value-of select="@smilref" />
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates />
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- linenum is translated to span with class -->
  <xsl:template match="dtb:linenum">
    <xsl:element name="span" use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>


  <!--*************************
        GENERAL BLOCKS
  ************************-->

  <!-- p maps directly -->
  <xsl:template match="dtb:p">
    <xsl:choose>
      <!--if (<p/> to <br/> -->
      <xsl:when test=". = ''">
        <br/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="p">
          <xsl:if test="@id">
            <xsl:attribute name="id">
              <xsl:value-of select="@id" />
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@smilref">
            <xsl:attribute name="smilref">
              <xsl:value-of select="@smilref" />
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates />
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- div maps directly -->
  <xsl:template match="dtb:div">
    <xsl:element name="div">
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- prodnote maps to div with class
       prodnote may contain bear text or block level elements, thus it must be wrapped in something, but it can't be p, otherwise we may end up with nested p
       Exclude: render attribute, no way to express -->
  <xsl:template match="dtb:prodnote">
    <xsl:element name="span"  use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- sidebar maps to div with class
       Exclude: render attribute, no way to express -->
  <xsl:template match="dtb:sidebar">
    <xsl:element name="span"  use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- address maps directly -->
  <xsl:template match="dtb:address">
    <xsl:element name="address">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- note maps to div with class -->
  <xsl:template match="dtb:note">
    <xsl:element name="span"  use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- annotation maps to div with class -->
  <xsl:template match="dtb:annotation">
    <xsl:element name="span"  use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- blockquote maps directly
       If applicable, include: cite -->
  <xsl:template match="dtb:blockquote">
    <xsl:element name="blockquote">
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@cite">
        <xsl:attribute name="cite">
          <xsl:value-of select="@cite"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- Map a line to a br tag -->
  <xsl:template match="dtb:line">
    <xsl:element name="p">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- poem maps to div with class -->
  <xsl:template match="dtb:poem">
    <xsl:element name="div">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- linegroup maps to div with class -->
  <xsl:template match="dtb:linegroup">
    <xsl:element name="div">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- byline is placed in a p with a class -->
  <xsl:template match="dtb:byline">
    <xsl:element name="p">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- dateline is placed in a p with a class -->
  <xsl:template match="dtb:dateline">
    <xsl:element name="p">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- epigraph maps to div with a class -->
  <xsl:template match="dtb:epigraph">
    <xsl:element name="div">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>


  <!--*************************
       GENERAL INLINES
  ************************-->

  <!-- a maps directly
       Include: one of href, id - include href if present, if not include id as a bookmark
       If applicable, include: charset, hreflang, rel, rev, type -->
  <xsl:template match="dtb:a">
    <xsl:element name="a">
      <xsl:if test="@charset">
        <xsl:attribute name="charset">
          <xsl:value-of select="@charset"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@hreflang">
        <xsl:attribute name="hreflang">
          <xsl:value-of select="@hreflang"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rel">
        <xsl:attribute name="rel">
          <xsl:value-of select="@rel"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rev">
        <xsl:attribute name="rev">
          <xsl:value-of select="@rev"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@type">
        <xsl:attribute name="type">
          <xsl:value-of select="@type"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:choose>
        <xsl:when test="@href">
          <xsl:attribute name="href">
            <xsl:value-of select="@href"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="id">
            <xsl:value-of select="@id"/>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="@external=true">
        <xsl:attribute name="target">_blank</xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- bdo maps directly,
       Include: dir -->
  <xsl:template match="dtb:bdo">
    <bdo dir="{@dir}">
      <xsl:apply-templates/>
    </bdo>
  </xsl:template>

  <!-- em maps directly -->
  <xsl:template match="dtb:em">
    <i>
      <xsl:apply-templates/>
    </i>
  </xsl:template>

  <!-- strong maps directly -->
  <xsl:template match="dtb:strong">
    <b>
      <xsl:apply-templates/>
    </b>
  </xsl:template>

  <!-- kbd maps directly -->
  <xsl:template match="dtb:kbd">
    <kbd>
      <xsl:apply-templates/>
    </kbd>
  </xsl:template>

  <!-- span maps to span for classes underline, strikethrough, double-strikethrough, small-caps, ruby -->
  <xsl:template match="dtb:span">
    <xsl:choose>
      <xsl:when test="@class='underline'">
        <!--span class="underline"><xsl:apply-templates/></span-->
        <u>
          <xsl:apply-templates/>
        </u>
      </xsl:when>
      <xsl:when test="@class='strikethrough'">
        <span class="strikethrough">
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:when test="@class='double-strikethrough'">
        <span class="double-strikethrough">
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:when test="@class='small-caps'">
        <span class="small-caps">
          <xsl:apply-templates/>
        </span>
      </xsl:when>

      <xsl:when test="@class='ruby'">
        <ruby>
          <xsl:apply-templates/>
        </ruby>
      </xsl:when>
      <xsl:when test="@class='rb'">
        <rb>
          <xsl:apply-templates/>
        </rb>
      </xsl:when>
      <xsl:when test="@class='rt'">
        <rt>
          <xsl:apply-templates/>
        </rt>
      </xsl:when>
      <xsl:when test="@class='rp'">
        <rp>
          <xsl:apply-templates/>
        </rp>
      </xsl:when>

      <xsl:otherwise>
        <span>
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- sub maps directly-->
  <xsl:template match="dtb:sub">
    <sub>
      <xsl:apply-templates/>
    </sub>
  </xsl:template>

  <!--sup maps directly-->
  <xsl:template match="dtb:sup">
    <sup>
      <xsl:apply-templates/>
    </sup>
  </xsl:template>

  <!-- abbr maps directly -->
  <xsl:template match="dtb:abbr">
    <abbr>
      <xsl:apply-templates/>
    </abbr>
  </xsl:template>

  <!-- acronym maps directly -->
  <xsl:template match="dtb:acronym">
    <acronym>
      <xsl:apply-templates/>
    </acronym>
  </xsl:template>

  <!-- dfn maps directly -->
  <xsl:template match="dtb:dfn">
    <dfn>
      <xsl:apply-templates/>
    </dfn>
  </xsl:template>

  <!-- code maps directly -->
  <xsl:template match="dtb:code">
    <code>
      <xsl:apply-templates/>
    </code>
  </xsl:template>

  <!-- samp maps directly -->
  <xsl:template match="dtb:samp">
    <samp>
      <xsl:apply-templates/>
    </samp>
  </xsl:template>

  <!-- cite maps directly -->
  <xsl:template match="dtb:cite">
    <cite>
      <xsl:apply-templates/>
    </cite>
  </xsl:template>

  <!--title-->

  <!-- author maps to p -->
  <xsl:template match="dtb:author">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- br maps directly
       NOTE: no apply-templates needed since this tag is always self closing-->
  <xsl:template match="dtb:br">
    <xsl:element name="br">
      <xsl:if test="@class">
        <xsl:attribute name="clear">
          <xsl:value-of select="@class"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-- q maps directly
       If applicable, includes: cite -->
  <xsl:template match="dtb:q">
    <xsl:element name="q">
      <xsl:if test="@cite">
        <xsl:attribute name="cite">
          <xsl:value-of select="@cite"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- noteref maps to span with class -->
  <xsl:template match="dtb:noteref">
    <xsl:element name="span" use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- annoref maps to span with class -->
  <xsl:template match="dtb:annoref">
    <xsl:element name="span" use-attribute-sets="skippableFramingStyle">
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)" />
      </xsl:attribute>
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- no equivalent tag -->
  <xsl:template match="dtb:sent">
    <xsl:element name="span">
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@smilref">
        <xsl:attribute name="smilref">
          <xsl:value-of select="@smilref" />
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

  <!-- no equivalent tag -->
  <xsl:template match="dtb:w">
    <xsl:apply-templates/>
  </xsl:template>


  <!--*************************
           LISTS
  ************************-->

  <!--Get fancy with the various list types-->

  <!-- An unordered list will be wrapped in ul tags -->
  <xsl:template match="dtb:list[@type='ul']">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <!-- A preformatted list will be wrapped in ul tags with an appropriate class.
       CSS can be used to turn off default display symbols, the list will still be
       rendered as such in the browser's DOM, which will let screen readers
       announce the item as a list -->
  <xsl:template match="dtb:list[@type='pl']">
    <ul class="pl">
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <!-- An ordered list will be wrapped in ol tags
       Ensure the desired formatting is preserved by pushing the enum attribute into the class attribute
           Note: replaces enum="1" with class="one" to ensure CSS 2.1 validation
       If applicable, include: start -->
  <xsl:template match="dtb:list[@type='ol']">
    <xsl:element name="ol">
      <xsl:choose>
        <xsl:when test="@enum='1'">
          <xsl:attribute name="class">one</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="class">
            <xsl:value-of select="@enum"/>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="@start">
        <xsl:attribute name="start">
          <xsl:value-of select="@start"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- li maps directly -->
  <xsl:template match="dtb:li">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <!-- lic maps to span -->
  <xsl:template match="dtb:lic">
    <span class="lic">
      <xsl:apply-templates/>
    </span>
  </xsl:template>


  <!-- *************************
         DEFINITION LIST
  ************************ -->

  <!-- dd maps directly -->
  <xsl:template match="dtb:dd">
    <dd>
      <xsl:apply-templates/>
    </dd>
  </xsl:template>

  <!-- dl maps directly -->
  <xsl:template match="dtb:dl">
    <dl>
      <xsl:apply-templates/>
    </dl>
  </xsl:template>

  <!-- dt maps directly -->
  <xsl:template match="dtb:dt">
    <dt>
      <xsl:apply-templates/>
    </dt>
  </xsl:template>


  <!--*************************
            TABLES
  ************************ *** -->

  <!-- table maps directly
       If applicable, include: border, cellpadding, cellspacing, frame, rules, summary, width -->
  <xsl:template match="dtb:table">
    <xsl:element name="table">
      <xsl:if test="@border">
        <xsl:attribute name="border">
          <xsl:value-of select="@border"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@cellpadding">
        <xsl:attribute name="cellpadding">
          <xsl:value-of select="@cellpadding"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@cellspacing">
        <xsl:attribute name="cellspacing">
          <xsl:value-of select="@cellspacing"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@frame">
        <xsl:attribute name="frame">
          <xsl:value-of select="@frame"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rules">
        <xsl:attribute name="rules">
          <xsl:value-of select="@rules"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@summary">
        <xsl:attribute name="summary">
          <xsl:value-of select="@summary"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@width">
        <xsl:attribute name="width">
          <xsl:value-of select="@width"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- table/caption maps directly -->
  <xsl:template match="dtb:table/dtb:caption">
    <caption>
      <xsl:apply-templates/>
    </caption>
  </xsl:template>

  <!-- tr maps directly
       If applicable, include: align, char, charoff, valign -->
  <xsl:template match="dtb:tr">
    <xsl:element name="tr">
      <xsl:if test="@align">
        <xsl:attribute name="align">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- col maps directly
       If applicable, include: align, char, charoff, span, valign, width
       NOTE: col is an empty element so no apply-templates necessary -->
  <xsl:template match="dtb:col">
    <xsl:element name="col">
      <xsl:if test="@align">
        <xsl:attribute name="align">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@span">
        <xsl:attribute name="span">
          <xsl:value-of select="@span"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@width">
        <xsl:attribute name="width">
          <xsl:value-of select="@width"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- colgroup maps directly
       If applicable, include: align, char, charoff, span, valign, width
       NOTE: colgroup is an empty element, so no apply-templates necessary -->
  <xsl:template match="dtb:colgroup">
    <xsl:element name="colgroup">
      <xsl:if test="@align">
        <xsl:attribute name="align">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@span">
        <xsl:attribute name="span">
          <xsl:value-of select="@span"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@width">
        <xsl:attribute name="width">
          <xsl:value-of select="@width"/>
        </xsl:attribute>
      </xsl:if>

    </xsl:element>
  </xsl:template>

  <!-- tbody maps directly
       If applicable, include: align, char, charoff, valign -->
  <xsl:template match="dtb:tbody">
    <xsl:element name="tbody">
      <xsl:if test="@align">
        <xsl:attribute name="algin">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- thead maps directly
       If applicable, include: align, char, charoff, valign -->
  <xsl:template match="dtb:thead">
    <xsl:element name="thead">
      <xsl:if test="@align">
        <xsl:attribute name="algin">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- tfoot maps directly
       If applicable, include: align, char, charoff, valign -->
  <xsl:template match="dtb:tfoot">
    <xsl:element name="tfoot">
      <xsl:if test="@align">
        <xsl:attribute name="algin">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- td maps directly
       If applicable, include: align, axis, char, charoff, colspan, headers, rowspan, scope, span, valign -->
  <xsl:template match="dtb:td">
    <xsl:element name="td">
      <xsl:if test="@align">
        <xsl:attribute name="align">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@axis">
        <xsl:attribute name="axis">
          <xsl:value-of select="@axis"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@colspan">
        <xsl:attribute name="colspan">
          <xsl:value-of select="@colspan"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@headers">
        <xsl:attribute name="headers">
          <xsl:value-of select="@headers"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rowspan">
        <xsl:attribute name="rowspan">
          <xsl:value-of select="@rowspan"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@scope">
        <xsl:attribute name="scope">
          <xsl:value-of select="@scope"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@span">
        <xsl:attribute name="span">
          <xsl:value-of select="@span"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- th maps directly
       If applicable, include: align, axis, char, charoff, colspan, headers, rowspan, scope, valign -->
  <xsl:template match="dtb:th">
    <xsl:element name="th">
      <xsl:if test="@align">
        <xsl:attribute name="align">
          <xsl:value-of select="@align"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@axi">
        <xsl:attribute name="axi">
          <xsl:value-of select="@axis"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@char">
        <xsl:attribute name="char">
          <xsl:value-of select="@char"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@charoff">
        <xsl:attribute name="charoff">
          <xsl:value-of select="@charoff"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@colspan">
        <xsl:attribute name="colspan">
          <xsl:value-of select="@colspan"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@headers">
        <xsl:attribute name="headers">
          <xsl:value-of select="@headers"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@rowspan">
        <xsl:attribute name="rowspan">
          <xsl:value-of select="@rowspan"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@scope">
        <xsl:attribute name="scope">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign">
        <xsl:attribute name="valign">
          <xsl:value-of select="@valign"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>


  <!--*************************
            IMAGES
  ************************ *** -->

  <!-- img maps directly
       Include: alt, src
       If applicable, include: longdesc, height, width
       NOTE: img is self closing so no apply-templates necessary -->
  <xsl:template match="dtb:img">
    <xsl:element name="img">
      <xsl:attribute name="alt">
        <xsl:value-of select="@alt"/>
      </xsl:attribute>
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:if test="@longdesc">
        <xsl:attribute name="longdesc">
          <xsl:value-of select="@longdesc"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@height">
        <xsl:attribute name="height">
          <xsl:value-of select="@height"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@width">
        <xsl:attribute name="width">
          <xsl:value-of select="@width"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@class">
        <xsl:attribute name="align">
          <xsl:value-of select="@class"/>
        </xsl:attribute>
      </xsl:if>

    </xsl:element>
  </xsl:template>

  <!-- imggroup maps to div with class -->
  <xsl:template match="dtb:imggroup">
    <div class="imggroup">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- imggroup/caption maps to div -->
  <xsl:template match="dtb:imggroup/dtb:caption">
    <div class="caption">
      <xsl:apply-templates/>
    </div>
  </xsl:template>


</xsl:stylesheet>
