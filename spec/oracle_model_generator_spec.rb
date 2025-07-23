require 'spec_helper'
require 'support/oracle_connection'
require 'oracle/model/generator'

RSpec.describe Oracle::Model::Generator do
  include_context 'Oracle connection'
  
  let(:generator) { described_class.new(connection) }

  describe 'class information' do
    it 'has the correct version number' do
      expect(Oracle::Model::Generator::VERSION).to eq('0.4.1')
    end
  end

  describe '#initialize' do
    it 'accepts an OCI8 connection object' do
      expect { described_class.new(connection) }.not_to raise_error
    end

    it 'sets up instance variables correctly' do
      expect(generator.connection).to eq(connection)
      expect(generator.constraints).to eq([])
      expect(generator.primary_keys).to eq([])
      expect(generator.foreign_keys).to eq([])
      expect(generator.dependencies).to eq([])
      expect(generator.belongs_to).to eq([])
      expect(generator.column_info).to eq([])
      expect(generator.table).to be_nil
      expect(generator.model).to be_nil
    end
  end

  describe '#generate' do
    it 'responds to the generate method' do
      expect(generator).to respond_to(:generate)
    end

    it 'works with a table name' do
      expect { generator.generate('employees') }.not_to raise_error
    end

    it 'works with a view name' do
      expect { generator.generate('emp_details_view', true) }.not_to raise_error
    end

    context 'when generating from a table' do
      before { generator.generate('employees') }

      it 'sets the table name in uppercase' do
        expect(generator.table).to eq('EMPLOYEES')
      end

      it 'generates a model name from the table name' do
        expect(generator.model).to eq('Employee')
      end

      it 'sets view to false' do
        expect(generator.view).to be false
      end

      it 'populates column information' do
        expect(generator.column_info).to be_an(Array)
        expect(generator.column_info).not_to be_empty
      end

      it 'finds primary keys' do
        expect(generator.primary_keys).to be_an(Array)
        expect(generator.primary_keys).to include('employee_id')
      end

      it 'populates constraints information' do
        expect(generator.constraints).to be_an(Array)
        expect(generator.constraints).not_to be_empty
      end
    end

    context 'when generating from a view' do
      before { generator.generate('emp_details_view', true) }

      it 'sets the table name in uppercase' do
        expect(generator.table).to eq('EMP_DETAILS_VIEW')
      end

      it 'generates the correct model name' do
        expect(generator.model).to eq('EmpDetailsView')
      end

      it 'sets view to true' do
        expect(generator.view).to be true
      end
    end
  end

  describe '#model' do
    it 'returns the active record model name' do
      generator.generate('emp_details_view', true)
      expect(generator).to respond_to(:model)
      expect(generator.model).to eq('EmpDetailsView')
    end

    it 'removes trailing s from model names' do
      generator.generate('employees')
      expect(generator.model).to eq('Employee')
    end
  end

  describe '#table' do
    it 'returns the uppercased table name' do
      generator.generate('emp_details_view', true)
      expect(generator).to respond_to(:table)
      expect(generator.table).to eq('EMP_DETAILS_VIEW')
    end
  end

  describe '#primary_keys' do
    it 'returns an array of primary keys' do
      generator.generate('employees')
      expect(generator.primary_keys).to be_an(Array)
      expect(generator.primary_keys).to include('employee_id')
    end
  end

  describe '#column_info' do
    it 'returns an array of column metadata' do
      generator.generate('employees')
      expect(generator.column_info).to be_an(Array)
      expect(generator.column_info.length).to be > 0
    end
  end

  describe '#constraints' do
    it 'returns an array of constraint information' do
      generator.generate('employees')
      expect(generator.constraints).to be_an(Array)
      expect(generator.constraints).not_to be_empty
    end
  end

  describe '#foreign_keys' do
    it 'returns an array of foreign key names' do
      generator.generate('employees')
      expect(generator.foreign_keys).to be_an(Array)
    end
  end

  describe '#belongs_to' do
    it 'returns an array of parent tables' do
      generator.generate('employees')
      expect(generator.belongs_to).to be_an(Array)
    end
  end

  describe '#dependencies' do
    it 'returns an array of dependent objects' do
      generator.generate('employees', true)
      expect(generator).to respond_to(:dependencies)
      expect(generator.dependencies).to be_an(Array)
      
      # Only check for Hash if there are dependencies
      if generator.dependencies.any?
        expect(generator.dependencies.first).to be_a(Hash)
      end
    end
  end

  describe '#view' do
    it 'correctly identifies tables vs views' do
      generator.generate('employees')
      expect(generator.view).to be false
      
      generator.generate('emp_details_view', true)
      expect(generator.view).to be true
    end
  end
end
