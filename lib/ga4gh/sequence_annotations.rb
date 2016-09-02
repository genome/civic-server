# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: ga4gh/sequence_annotations.proto

require 'google/protobuf'

require 'ga4gh/common'
require 'ga4gh/metadata'
require 'google/protobuf/struct_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "ga4gh.Attributes" do
    map :vals, :string, :message, 1, "ga4gh.Attributes.AttributeValueList"
  end
  add_message "ga4gh.Attributes.AttributeValue" do
    oneof :value do
      optional :string_value, :string, 1
      optional :external_identifier, :message, 2, "ga4gh.ExternalIdentifier"
      optional :ontology_term, :message, 3, "ga4gh.OntologyTerm"
    end
  end
  add_message "ga4gh.Attributes.AttributeValueList" do
    repeated :values, :message, 1, "ga4gh.Attributes.AttributeValue"
  end
  add_message "ga4gh.Feature" do
    optional :id, :string, 1
    optional :name, :string, 2
    optional :gene_symbol, :string, 3
    optional :parent_id, :string, 4
    repeated :child_ids, :string, 5
    optional :feature_set_id, :string, 6
    optional :reference_name, :string, 7
    optional :start, :int64, 8
    optional :end, :int64, 9
    optional :strand, :enum, 10, "ga4gh.Strand"
    optional :feature_type, :message, 11, "ga4gh.OntologyTerm"
    optional :attributes, :message, 12, "ga4gh.Attributes"
  end
  add_message "ga4gh.FeatureSet" do
    optional :id, :string, 1
    optional :dataset_id, :string, 2
    optional :reference_set_id, :string, 3
    optional :name, :string, 4
    optional :source_uri, :string, 5
    map :info, :string, :message, 6, "google.protobuf.ListValue"
  end
end

module Ga4gh
  Attributes = Google::Protobuf::DescriptorPool.generated_pool.lookup("ga4gh.Attributes").msgclass
  Attributes::AttributeValue = Google::Protobuf::DescriptorPool.generated_pool.lookup("ga4gh.Attributes.AttributeValue").msgclass
  Attributes::AttributeValueList = Google::Protobuf::DescriptorPool.generated_pool.lookup("ga4gh.Attributes.AttributeValueList").msgclass
  Feature = Google::Protobuf::DescriptorPool.generated_pool.lookup("ga4gh.Feature").msgclass
  FeatureSet = Google::Protobuf::DescriptorPool.generated_pool.lookup("ga4gh.FeatureSet").msgclass
end
