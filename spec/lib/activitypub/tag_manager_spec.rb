require 'rails_helper'

RSpec.describe ActivityPub::TagManager do
  include RoutingHelper

  subject { described_class.instance }

  describe '#url_for' do
    it 'returns a string' do
      account = Fabricate(:account)
      expect(subject.url_for(account)).to be_a String
    end
  end

  describe '#uri_for' do
    it 'returns a string' do
      account = Fabricate(:account)
      expect(subject.uri_for(account)).to be_a String
    end
  end

  describe '#to' do
    it 'returns public collection for public status' do
      status = Fabricate(:status, visibility: :public)
      expect(subject.to(status)).to eq ['https://www.w3.org/ns/activitystreams#Public']
    end

    it 'returns followers collection for unlisted status' do
      status = Fabricate(:status, visibility: :unlisted)
      expect(subject.to(status)).to eq [account_followers_url(status.account)]
    end

    it 'returns followers collection for private status' do
      status = Fabricate(:status, visibility: :private)
      expect(subject.to(status)).to eq [account_followers_url(status.account)]
    end

    it 'returns URIs of mentions for direct status' do
      status    = Fabricate(:status, visibility: :direct)
      mentioned = Fabricate(:account)
      status.mentions.create(account: mentioned)
      expect(subject.to(status)).to eq [subject.uri_for(mentioned)]
    end
  end

  describe '#cc' do
    it 'returns followers collection for public status' do
      status = Fabricate(:status, visibility: :public)
      expect(subject.cc(status)).to eq [account_followers_url(status.account)]
    end

    it 'returns public collection for unlisted status' do
      status = Fabricate(:status, visibility: :unlisted)
      expect(subject.cc(status)).to eq ['https://www.w3.org/ns/activitystreams#Public']
    end

    it 'returns empty array for private status' do
      status = Fabricate(:status, visibility: :private)
      expect(subject.cc(status)).to eq []
    end

    it 'returns empty array for direct status' do
      status = Fabricate(:status, visibility: :direct)
      expect(subject.cc(status)).to eq []
    end

    it 'returns URIs of mentions for non-direct status' do
      status    = Fabricate(:status, visibility: :public)
      mentioned = Fabricate(:account)
      status.mentions.create(account: mentioned)
      expect(subject.cc(status)).to include(subject.uri_for(mentioned))
    end
  end

  describe '#local_uri?' do
    it 'returns false for non-local URI' do
      expect(subject.local_uri?('http://example.com/123')).to be false
    end

    it 'returns true for local URIs' do
      account = Fabricate(:account)
      expect(subject.local_uri?(subject.uri_for(account))).to be true
    end
  end

  describe '#uri_to_local_id' do
    it 'returns the local ID' do
      account = Fabricate(:account)
      expect(subject.uri_to_local_id(subject.uri_for(account), :username)).to eq account.username
    end
  end

  describe '#uri_to_resource' do
    it 'returns the local account' do
      account = Fabricate(:account)
      expect(subject.uri_to_resource(subject.uri_for(account), Account)).to eq account
    end

    it 'returns the remote account by matching URI without fragment part' do
      account = Fabricate(:account, uri: 'https://example.com/123')
      expect(subject.uri_to_resource('https://example.com/123#456', Account)).to eq account
    end

    it 'returns the local status for ActivityPub URI' do
      status = Fabricate(:status)
      expect(subject.uri_to_resource(subject.uri_for(status), Status)).to eq status
    end

    it 'returns the local status for OStatus tag: URI' do
      status = Fabricate(:status)
      expect(subject.uri_to_resource(OStatus::TagManager.instance.uri_for(status), Status)).to eq status
    end

    it 'returns the local status for OStatus StreamEntry URL' do
      status = Fabricate(:status)
      stream_entry_url = account_stream_entry_url(status.account, status.stream_entry)
      expect(subject.uri_to_resource(stream_entry_url, Status)).to eq status
    end

    it 'returns the remote status by matching URI without fragment part' do
      status = Fabricate(:status, uri: 'https://example.com/123')
      expect(subject.uri_to_resource('https://example.com/123#456', Status)).to eq status
    end
  end
end
