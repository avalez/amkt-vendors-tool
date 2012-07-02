require 'csv'    

class License 
  def self.all_editions
    {'Evaluation' => 0, '10 Users' => 10, '25 Users' => 10, '50 Users' => 50, '100 Users' => 50,
     '500 Users' => 50, 'Enterprise 10000+ Users' => 100, 'Unlimited Users' => 100}
  end

  def self.find filter
    csv_text = File.read('licenseReport.csv')
    csv = CSV.parse(csv_text, :headers => true)
    if (filter && filter != :all)
      csv.find_all {|license| filter.index license['edition']}
    else
      csv
    end
  end
end
