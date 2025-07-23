require 'rspec'
require_relative 'customer_test'

RSpec.describe Customer do
  let(:customer) { Customer.new }

  describe 'table configuration' do
    it 'has table name customers' do
      expect(Customer.table_name).to eq('customers')
    end
    it 'has primary key id' do
      expect(Customer.primary_key).to eq('id')
    end
  end

  describe 'id column' do
    it 'responds to id' do
      expect(customer).to respond_to(:id)
    end
    it 'validates id presence' do
      customer.id = nil
      expect(customer).not_to be_valid
      expect(customer.errors[:id]).to include("can't be blank")
  end
  end

  describe 'name column' do
    it 'responds to name' do
      expect(customer).to respond_to(:name)
      expect(customer.name).to be_a(String)
    end
    it 'validates name as a string' do
      customer.name = 65
      expect(customer).not_to be_valid
      expect(customer.errors[:name]).to include('is not a string')
  end
    it 'validates name length cannot exceed 100 characters' do
      customer.name = 'a' * 101
      expect(customer).not_to be_valid
      expect(customer.errors[:name]).to include('is too long (maximum is 100 characters)')
  end
    it 'validates name presence' do
      customer.name = nil
      expect(customer).not_to be_valid
      expect(customer.errors[:name]).to include("can't be blank")
  end
  end

  describe 'email column' do
    it 'responds to email' do
      expect(customer).to respond_to(:email)
      expect(customer.email).to be_a(String).or be_nil
    end
    it 'validates email as a string if present' do
      customer.email = 24
      expect(customer).not_to be_valid
      expect(customer.errors[:email]).to include('is not a string')
  end
    it 'validates email length cannot exceed 255 characters' do
      customer.email = 'a' * 256
      expect(customer).not_to be_valid
      expect(customer.errors[:email]).to include('is too long (maximum is 255 characters)')
  end
  end

  describe 'status column' do
    it 'responds to status' do
      expect(customer).to respond_to(:status)
      expect(customer.status).to be_a(String).or be_nil
    end
    it 'validates status as a string if present' do
      customer.status = 96
      expect(customer).not_to be_valid
      expect(customer.errors[:status]).to include('is not a string')
  end
    it 'validates status length cannot exceed 20 characters' do
      customer.status = 'a' * 21
      expect(customer).not_to be_valid
      expect(customer.errors[:status]).to include('is too long (maximum is 20 characters)')
  end
  end
end
