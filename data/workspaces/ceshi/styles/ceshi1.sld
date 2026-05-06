<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.1.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:se="http://www.opengis.net/se"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>ceshi</se:Name>
    <UserStyle>
      <se:Name>ceshi_style</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:Name>Polygon Fill</se:Name>
          <!-- 基础填充 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#e61957</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0</se:SvgParameter>
            </se:Fill>
          </se:PolygonSymbolizer>
          <!-- 品字形排列：中心点（较大） -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="ceshi.svg?fill=%23e61957"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>19.2</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:VendorOption name="graphic-margin">12 12</se:VendorOption>
          </se:PolygonSymbolizer>
          <!-- 品字形排列：四角点 -->
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="ceshi.svg?fill=%23e61957"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>12.8</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:Displacement>
              <se:DisplacementX>-3.5999999999999996</se:DisplacementX>
              <se:DisplacementY>-3.5999999999999996</se:DisplacementY>
            </se:Displacement>
            <se:VendorOption name="graphic-margin">12 12</se:VendorOption>
          </se:PolygonSymbolizer>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="ceshi.svg?fill=%23e61957"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>12.8</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:Displacement>
              <se:DisplacementX>3.5999999999999996</se:DisplacementX>
              <se:DisplacementY>-3.5999999999999996</se:DisplacementY>
            </se:Displacement>
            <se:VendorOption name="graphic-margin">12 12</se:VendorOption>
          </se:PolygonSymbolizer>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="ceshi.svg?fill=%23e61957"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>12.8</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:Displacement>
              <se:DisplacementX>-3.5999999999999996</se:DisplacementX>
              <se:DisplacementY>3.5999999999999996</se:DisplacementY>
            </se:Displacement>
            <se:VendorOption name="graphic-margin">12 12</se:VendorOption>
          </se:PolygonSymbolizer>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:GraphicFill>
                <se:Graphic>
                  <se:ExternalGraphic>
                    <se:OnlineResource xlink:type="simple" xlink:href="ceshi.svg?fill=%23e61957"/>
                    <se:Format>image/svg+xml</se:Format>
                  </se:ExternalGraphic>
                  <se:Size>12.8</se:Size>
                </se:Graphic>
              </se:GraphicFill>
            </se:Fill>
            <se:Displacement>
              <se:DisplacementX>3.5999999999999996</se:DisplacementX>
              <se:DisplacementY>3.5999999999999996</se:DisplacementY>
            </se:Displacement>
            <se:VendorOption name="graphic-margin">12 12</se:VendorOption>
          </se:PolygonSymbolizer>
          <se:LineSymbolizer>
            <se:Stroke>
              <se:SvgParameter name="stroke">#b48031</se:SvgParameter>
              <se:SvgParameter name="stroke-width">1</se:SvgParameter>
            </se:Stroke>
          </se:LineSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>