module Cetustek
  class CreateInvoice
    def initialize(order)
      @order = order
    end

    def execute
      generate_invoice_xml
      perform
      analize_response
    end

    private

    def perform
      url = Cetustek.config.url
      client = Savon.client(
        wsdl: url,
        open_timeout: 300,
        read_timeout: 300
      )

      @response = client.call(:create_invoice_v3, message:
        { invoicexml: @xml,
          source: Cetustek.config.site_id + Cetustek.config.password,
          rentid: Cetustek.config.username,
          hastax: 1 })

      logger = Logger.new(Rails.root.join('log/invoice.log'))
      logger.debug("#{@order.id} - #{@response.body}")
    end

    def generate_invoice_xml
      doc = Ox::Document.new

      instruct = Ox::Instruct.new(:xml)
      instruct[:version] = '1.0'
      instruct[:encoding] = 'UTF-8'
      doc << instruct

      invoice = Ox::Element.new('Invoice')
      invoice[:XSDVersion] = '2.8'
      doc << invoice

      invoice << Ox::Raw.new("<OrderId>#{@order.hashed_id}</OrderId>")
      invoice << Ox::Raw.new("<OrderDate>#{Time.zone.today.strftime('%Y/%m/%d')}</OrderDate>")
      invoice << Ox::Raw.new("<BuyerIdentifier>#{@order.invoice_info.receipt}</BuyerIdentifier>")
      invoice << Ox::Raw.new("<BuyerName>#{CGI.escapeHTML(@order.invoice_info.name || @order.sender_name || 'Customer')}</BuyerName>")
      invoice << Ox::Raw.new("<BuyerEmailAddress>#{email}</BuyerEmailAddress>")
      invoice << Ox::Raw.new("<DonateMark>#{donate_mark}</DonateMark>")
      invoice << Ox::Raw.new('<InvoiceType>07</InvoiceType>')
      invoice << Ox::Raw.new("<CarrierType>#{carrier_type}</CarrierType>")
      invoice << Ox::Raw.new("<CarrierId1>#{carrier_id1}</CarrierId1>")
      invoice << Ox::Raw.new("<CarrierId2>#{carrier_id2}</CarrierId2>")
      invoice << Ox::Raw.new("<NPOBAN>#{npoban}</NPOBAN>")
      invoice << Ox::Raw.new('<TaxType>1</TaxType>')
      invoice << Ox::Raw.new("<PayWay>#{pay_way}</PayWay>")

      products = Ox::Element.new('Details')
      invoice << products
      @order.order_details.main_products.includes(product: [:translations]).find_each do |detail|
        item = Ox::Element.new('ProductItem')
        item << Ox::Raw.new("<ProductionCode>#{detail.product_sku}</ProductionCode>")
        item << Ox::Raw.new("<Description>#{CGI.escapeHTML(detail.product_name)}</Description>")
        item << Ox::Raw.new("<Quantity>#{detail.quantity}</Quantity>")

        item << if detail.shopping_point_cost > 0
                  Ox::Raw.new("<UnitPrice>#{detail.product.price}</UnitPrice>")
                else
                  Ox::Raw.new("<UnitPrice>#{detail.unit_price}</UnitPrice>")
                end

        products << item
      end

      shopping_point = Ox::Element.new('ProductItem')
      shopping_point << Ox::Raw.new('<ProductionCode>DISCOUNT</ProductionCode>')
      shopping_point << Ox::Raw.new('<Description>折抵金額</Description>')
      shopping_point << Ox::Raw.new('<Quantity>1</Quantity>')
      shopping_point << Ox::Raw.new("<UnitPrice>#{@order.total_discount * -1}</UnitPrice>")

      coupon = Ox::Element.new('ProductItem')
      coupon << Ox::Raw.new('<ProductionCode>COUPON</ProductionCode>')
      coupon << Ox::Raw.new('<Description>分享折讓</Description>')
      coupon << Ox::Raw.new('<Quantity>1</Quantity>')
      coupon << Ox::Raw.new("<UnitPrice>#{@order.coupon * -1}</UnitPrice>")

      delivery_fee = Ox::Element.new('ProductItem')
      delivery_fee << Ox::Raw.new('<ProductionCode>DELIVERY_FEE</ProductionCode>')
      delivery_fee << Ox::Raw.new('<Description>運費</Description>')
      delivery_fee << Ox::Raw.new('<Quantity>1</Quantity>')
      delivery_fee << Ox::Raw.new("<UnitPrice>#{@order.delivery_fee}</UnitPrice>")

      handling_fee = Ox::Element.new('ProductItem')
      handling_fee << Ox::Raw.new('<ProductionCode>HANDLING_FEE</ProductionCode>')
      handling_fee << Ox::Raw.new('<Description>手續費</Description>')
      handling_fee << Ox::Raw.new('<Quantity>1</Quantity>')
      handling_fee << Ox::Raw.new("<UnitPrice>#{@order.handling_fee}</UnitPrice>")

      products << shopping_point << coupon << delivery_fee << handling_fee
      @xml = Ox.dump(doc)
    end

    def analize_response
      number, random_number = @response.body[:create_invoice_v3_response][:return].split(';')

      unless random_number
        logger_xml = Logger.new(Rails.root.join('log/invoice_xml.log'))
        logger_xml.debug("#{@order.id} - #{@xml.force_encoding('UTF-8')}")
        return
      end

      @order.invoice_info.update(number: number, random_number: random_number, created_at: Time.zone.today)
    end

    def email
      return @order.invoice_info.carrier if @order.invoice_info.member?

      @order.user.email
    end

    def carrier_type
      return '3J0002' if @order.invoice_info.mobile?

      'CQ0001' if @order.invoice_info.citizen?
    end

    def carrier_id1
      @order.invoice_info.carrier if @order.invoice_info.mobile? || @order.invoice_info.citizen?
    end

    def carrier_id2
      @order.invoice_info.carrier if @order.invoice_info.mobile? || @order.invoice_info.citizen?
    end

    def npoban
      @order.invoice_info.carrier if @order.invoice_info.donate?
    end

    def pay_way
      return 3 if @order.credit_cards?
      return 2 if @order.atm?

      1
    end

    def donate_mark
      case @order.invoice_info.carrier_type
      when 'member', 'mobile', 'citizen'
        0
      when 'donate'
        1
      when 'paper'
        2
      end
    end
  end
end
