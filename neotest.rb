require 'csv'
require 'rubygems'
require 'neography'

@neo = Neography::Rest.new :log_enabled => true

# -- Organisation --

def get_org(name)
    @neo.execute_query("start root=node(0) match root-[:organisation]-org where org.name = {orgName} return org",
      {:orgName => name})   
end
  
def create_org(name)
    root = @neo.get_root
    org = @neo.create_node(:name => name)
    @neo.create_relationship(:organisation, root, org)
    org
end

def get_or_create_org(name)
    org = get_org(name)
    if (org['data'].length == 0)
        org = create_org name
    else
        org = org['data'][0]
    end
    org
end

# -- Add On --

def get_add_on_by_key(key)
    @neo.get_node_index(:AddOns, :key, key) 
end
  
def create_add_on(key, name)
    add_on = @neo.create_node(:key => key, :name => name)
    @neo.add_node_to_index(:AddOns, :key, key, add_on) 
    @neo.create_relationship(:ROOT, @neo.get_root, add_on)
    add_on
end

def get_or_create_add_on_by_key(key, name)
    add_on = get_add_on_by_key(key)
    if (!add_on)
        add_on = create_add_on(key, name)
    end
    add_on
end

# -- Contact

def get_contact_by_email(email)
    @neo.get_node_index("Contacts", :email, email) 
end
  
def create_contact(email, name, phone)
    contact = @neo.create_node(:email => email, :name => name, :phone => phone)
    @neo.add_node_to_index(:Contacts, :email, email, contact) 
    contact
end

def get_or_create_contact_by_email(email, attrs)
    contact = get_contact_by_email(email)
    if (!contact)
        contact = create_contact(email, attrs[:name], attrs[:phone])
    end
    contact
end

# -- License

def get_license_by_licenseId(licenseId)
    @neo.get_node_index(:Licenses, :licenseId, licenseId) 
end
  
def create_license(licenseId, organisationName, addOn, technicalContact, technicalContactAddress,
        billingContact, edition, licenseType, startDate, endDate, renewalAction)
    license = @neo.create_node(:licenseId => licenseId, :organisationName => organisationName,
        :edition => edition, :licenseType => licenseType, :startDate => startDate, :endDate => endDate)
    @neo.add_node_to_index(:Licenses, :licenseId, licenseId, license) 
    @neo.create_relationship("addOn", license, addOn)
    @neo.create_relationship("technicalContact", license, technicalContact)
    #TODO: @neo.create_relationship("address", technicalContact, technicalContactAddress)
    @neo.create_relationship("billingContact", license, billingContact)
    license
end

def get_or_create_license_by_licenseId(licenseId, attrs)
    license = get_license_by_licenseId(licenseId)
    if (!license)
        license = create_license(licenseId, attrs[:organisationName], attrs[:addOn],
        attrs[:technicalConact], attrs[:technicalContactAddress],
        attrs[:billingContact], attrs[:edition], attrs[:licenseType], attrs[:startDate],
        attrs[:endDate], attrs[:renewalAction])
    end
    license
end

# -- Import --

def import_row(row)
    addOn = get_or_create_add_on_by_key row['addOnKey'], :name => row['addOnName']
    technicalContact = get_or_create_contact_by_email row['technicalContactEmail'],
        :name => row['technicalContactName'], :phone => row['technicalContactPhone']
    billingContact = get_or_create_contact_by_email row['billingContactEmail'],
        :name => row['billingContactName'], :phone => row['billingContactPhone']
    license = get_or_create_license_by_licenseId row['licenseId'],
      :organisationName => row['organisationName'], :addOn => addOn,
      :technicalContact => technicalContact,
      :technicalContactAddress => nil, # FIXME
      :billingContact_id => billingContact,
      :edition => row['edition'], :licenseType => row['licenseType'],
      :startDate => row['startDate'], :endDate => row['endDate'],
      :renewalAction => row['renewalAction']
end

def import
    csv_text = File.read('licenseReport.csv')
    csv = CSV.parse(csv_text, :headers => true)
    import_row csv.first
end

puts import

#ERROR -- : Invalid data sent {
#  "message" : "Could not set property \"name\", unsupported type: {name=JIRA Timesheet Reports and Gadgets Plugin}",
#ERROR -- : Invalid data sent {
#  "message" : "For input string: \"\"",
#  "exception" : "org.neo4j.server.rest.repr.BadInputException: For input string: \"\"",
