module Cetustek
  class CancelInvoice
    def initialize(invoice)
      @invoice = invoice
    end

    def execute
      generate_xml
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

      @response = client.call(:cancel_invoice, message:
        { invoicexml: @xml,
          source: Cetustek.config.site_id + Cetustek.config.password,
          rentid: Cetustek.config.username })
    end

    def generate_xml
      doc = Ox::Document.new

      instruct = Ox::Instruct.new(:xml)
      instruct[:version] = '1.0'
      instruct[:encoding] = 'UTF-8'
      instruct[:standalone] = 'yes'
      doc << instruct

      invoice = Ox::Element.new('Invoice')
      invoice[:XSDVersion] = '2.8'
      doc << invoice

      invoice << Ox::Raw.new("<InvoiceNumber>#{@invoice.number}</InvoiceNumber>")
      invoice << Ox::Raw.new("<InvoiceYear>#{@invoice.created_at.year}</InvoiceYear>")
      invoice << Ox::Raw.new('<Remark>退貨</Remark>')
      @xml = Ox.dump(doc)
    end

    def analize_response
      return unless @response.body[:cancel_invoice_response][:return] == 'C0'

      @invoice.update(canceled: true)
    end
  end
end
