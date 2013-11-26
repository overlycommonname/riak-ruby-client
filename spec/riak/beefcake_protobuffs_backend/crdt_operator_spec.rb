require 'spec_helper'
Riak::Client::BeefcakeProtobuffsBackend.configured?

describe Riak::Client::BeefcakeProtobuffsBackend::CrdtOperator do

  let(:backend_class){ Riak::Client::BeefcakeProtobuffsBackend }

  describe 'operating on a counter' do
    let(:increment){ 5 }
    let(:operation) do
      Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :counter
        op.value = increment
      end
    end
    
    subject { described_class.new }
    
    it 'should serialize a counter operation into protobuffs' do
      result = subject.serialize operation

      expect(result).to be_a backend_class::DtOp
      expect(result.counter_op).to be_a backend_class::CounterOp
      expect(result.counter_op.increment).to eq increment
    end
  end

  describe 'operating on a set' do
    let(:added_element){ 'added_element' }
    let(:removed_element){ 'removed_element' }
    let(:operation) do
      Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :set
        op.value = {
          add: [added_element],
          remove: [removed_element]
        }
      end
    end

    it 'should serialize a set operation into protobuffs' do
      result = subject.serialize operation
      
      expect(result).to be_a backend_class::DtOp
      expect(result.set_op).to be_a backend_class::SetOp
      expect(result.set_op.adds).to eq [added_element]
      expect(result.set_op.removes).to eq [removed_element]
    end
  end

  describe 'operating on a map' do
    it 'should serialize inner counter operations' do
      counter_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_counter'
        op.type = :counter
        op.value = 12345
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = counter_op
      end

      result = subject.serialize map_op

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.counter_op).to be_a backend_class::CounterOp
      expect(map_update.counter_op.increment).to eq 12345
    end
    
    it 'should serialize inner flag operations' do
      flag_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_flag'
        op.type = :flag
        op.value = true
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = flag_op
      end

      result = subject.serialize map_op

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.flag_op).to eq backend_class::MapUpdate::FlagOp::ENABLE
    end

    it 'should serialize inner register operations' do
      register_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_register'
        op.type = :register
        op.value = 'hello'
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = register_op
      end

      result = subject.serialize map_op

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.register_op).to eq 'hello'
    end
    it 'should serialize inner set operations'
    it 'should serialize inner map operations'
  end
end
