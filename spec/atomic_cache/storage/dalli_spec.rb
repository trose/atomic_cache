# frozen_string_literal: true

require 'spec_helper'

class FakeDalli
  def add(key, new_value, ttl, user_options); end
  def read(key, user_options); end
  def set(key, new_value, user_options); end
  def delete(key, user_options); end
end

describe 'Dalli' do
  let(:dalli_client) { FakeDalli.new }
  subject { AtomicCache::Storage::Dalli.new(dalli_client) }

  it 'delegates #set without options' do
    expect(dalli_client).to receive(:set).with('key', 'value', {})
    subject.set('key', 'value')
  end

  it 'delegates #read without options' do
    expect(dalli_client).to receive(:read).with('key', {})
    subject.read('key')
  end

  it 'delegates #delete' do
    expect(dalli_client).to receive(:delete).with('key')
    subject.delete('key')
  end

  context '#add' do
    before(:each) do
      allow(dalli_client).to receive(:add).and_return('NOT_STORED\r\n')
    end

    it 'delegates to #add with the raw option set' do
      expect(dalli_client).to receive(:add)
        .with('key', 'value', 100, { foo: 'bar', raw: true })
      subject.add('key', 'value', 100, { foo: 'bar' })
    end

    it 'returns true when the add is successful' do
      expect(dalli_client).to receive(:add).and_return('STORED\r\n')
      result = subject.add('key', 'value', 100)
      expect(result).to eq(true)
    end

    it 'returns false if the key already exists' do
      expect(dalli_client).to receive(:add).and_return('EXISTS\r\n')
      result = subject.add('key', 'value', 100)
      expect(result).to eq(false)
    end

    it 'returns false if the add fails' do
      expect(dalli_client).to receive(:add).and_return('NOT_STORED\r\n')
      result = subject.add('key', 'value', 100)
      expect(result).to eq(false)
    end
  end

end
