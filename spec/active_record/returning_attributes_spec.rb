RSpec.describe ActiveRecord::ReturningAttributes do
  let(:project) { Project.create(name: 'Freshly Created') }

  context 'without returning attributes' do
    before do
      Project.returning_attributes = []
    end

    context 'on insert' do
      it 'doesn’t return database-backed default values' do
        expect(project.uuid).to be_nil
      end
    end

    context 'on update' do
      it 'doesn’t return values set via database triggers' do
        project.update(name: 'Just Updated')
        expect(project.update_count).to eq(0)
      end
    end
  end

  context 'with returning attributes' do
    before do
      Project.returning_attributes = [:uuid, :update_count]
    end

    context 'on insert' do
      it 'returns database-backed default values' do
        expect(project.uuid).to be_present
      end
    end

    context 'on update' do
      it 'returns values set via database triggers' do
        project.update(name: 'Just Updated')
        expect(project.update_count).to eq(1)
      end
    end
  end
end
