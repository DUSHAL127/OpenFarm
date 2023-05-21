require 'spec_helper'
require 'openfarm_errors'

describe StageActions::CreateStageAction do
  let(:mutation) { StageActions::CreateStageAction }
  let(:stage) { FactoryBot.create(:stage) }
  let(:params) do
    { user: stage.guide.user,
      id: "#{stage._id}",
      attributes: { name: Faker::Name.last_name,
                    overview: Faker::Lorem.paragraph } }
  end

  it 'minimally runs the mutation' do
    results = mutation.run(params)
    expect(results.success?).to be_truthy
  end

  it 'disallows making actions for stages that are not a users' do
    user = FactoryBot.create(:user)
    params[:user] = user
    expect { mutation.run(params) }.to raise_exception(OpenfarmErrors::NotAuthorized)
  end

  it 'uploads multiple images' do
    VCR.use_cassette('mutations/stages/create_stage') do
      image_hash = [{ image_url: 'http://i.imgur.com/2haLt4J.jpg' },
                    { image_url: 'http://i.imgur.com/kpHLl.jpg' }]
      image_params = params.merge(images: image_hash)
      results = mutation.run(image_params)
      pics = results.result.pictures
      expect(pics.count).to eq(2)
    end
  end

  it 'disallows phony URLs' do
    image_hash = {
      image_url: 'iWroteThisWrong.net/2haLt4J.jpg'
    }
    image_params = params.merge(images: [image_hash])
    results = mutation.run(image_params)
    expect(results.success?).to be_falsey
    expect(results.errors.message[:images]).to include('not a valid URL')
  end

  it 'disallows making actions for stages that do not exist' do
    params[:id] = '1'
    results = mutation.run(params)
    expect(results.success?).to be_falsey
    expect(results.errors.message_list).to include('Could not find a stage '\
                                                   'with id 1.')
  end
end
