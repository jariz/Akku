require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Amimono do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ amimono }).should.be.instance_of Command::Amimono
      end
    end
  end
end

