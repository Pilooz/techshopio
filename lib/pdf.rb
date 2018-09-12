# coding: utf-8
require 'pdfkit'

class Pdf
	kit = {}
	def initialize(html)
		#html = self.header + html + self.footer
		kit = PDFKit.new(html, :page_size => 'Letter')
		puts 80.times { putc '-' }
		puts File.exists?('../public/css/bootstrap.css')
		kit.stylesheets << '../public/css/bootstrap.css'
		pdf = kit.to_pdf
		puts pdf.inspect
		pdf
	end

	def header
		"<html><head><title></title></head><body>"
	end

	def footer
		"</body></html>"
	end
end
