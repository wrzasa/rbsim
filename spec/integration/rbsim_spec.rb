require 'spec_helper'

require 'tempfile'

describe RBSim do

  describe "#model" do
    it "passes its params to the loaded model" do
      o = Object.new
      expect(o).to receive(:to_s)
      m = RBSim.model name: :apache, run: true do |params|
        o.to_s
        expect(params[:name]).to eq :apache
        expect(params[:run]).to be true
      end
      m.hlmodel
    end
  end

  describe "#read" do
    it "reads model from file" do
      file = Tempfile.new "rbsim_model_test"
      file.write "program :prg do;end"
      file.close
      m = RBSim.read file.path
      file.unlink
      expect(m.hlmodel.programs).to have_key :prg
    end

    it "passes params to the model from file as 'params' variable" do
      file = Tempfile.new "rbsim_model_test"
      file.write "program params[:name] do;end"
      file.close
      m = RBSim.read file.path, name: :prg
      file.unlink
      expect(m.hlmodel.programs).to have_key :prg
    end

  end
end
