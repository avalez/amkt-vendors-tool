require 'csv'    

class License 
  def self.find ignore
    csv_text = File.read('licenseReport.csv')
    csv = CSV.parse(csv_text, :headers => true)
  end
end
