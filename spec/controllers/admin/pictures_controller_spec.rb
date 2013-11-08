require 'spec_helper'

module Alchemy
  describe Admin::PicturesController do

    before do
      sign_in(admin_user)
    end

    describe "#index" do
      it "should always paginate the records" do
        Picture.should_receive(:find_paginated)
        get :index
      end

      context "when params[:filter] is set" do
        it "should filter the pictures collection by the given filter string." do
          Picture.should_receive(:filtered_by).with('recent').and_return(Picture.all)
          get :index, filter: 'recent'
        end
      end

      context "when params[:tagged_with] is set" do
        it "should filter the records by tags" do
          Picture.should_receive(:tagged_with).and_return(Picture.all)
          get :index, tagged_with: "red"
        end
      end

      context "when params[:content_id]" do
        context "is set" do
          it "should render the archive_overlay partial" do
            Element.stub(:find).with('1', {:select => 'id'}).and_return(mock_model(Element))
            get :index, {element_id: 1}
            expect(response).to render_template(partial: '_archive_overlay')
          end
        end

        context "is not set" do
          it "should render the default index view" do
            get :index
            expect(response).to render_template(:index)
          end
        end

      end
    end

    describe '#new' do
      subject { get :new, params }

      let(:params) { Hash.new }

      context 'if inside of archive overlay' do
        let(:params)  { {element_id: 1, content_id: 1} }
        let(:element) { mock_model('Element') }
        let(:content) { mock_model('Content') }

        before do
          Content.stub_chain(:select, :find_by_id).and_return(content)
          Element.stub_chain(:select, :find_by_id).and_return(element)
        end

        it "assigns lots of instance variables" do
          subject
          assigns(:options).should eq({})
          assigns(:while_assigning).should be_true
          assigns(:content).should eq(content)
          assigns(:element).should eq(element)
          assigns(:page).should eq(1)
          assigns(:per_page).should eq(9)
        end
      end

      context 'with size param given' do
        let(:params) { {size: '200x200'} }
        before { subject }
        it { assigns(:size).should eq('200x200') }
      end

      context 'without size param given' do
        let(:params) { {size: nil} }
        before { subject }
        it { assigns(:size).should eq('medium') }
      end
    end

    describe '#create' do
      subject { post :create, params }

      let(:params)  { Hash.new }
      let(:picture) { mock_model('Picture', humanized_name: 'Cute kittens') }

      before do
        Picture.should_receive(:new).and_return(picture)
        picture.should_receive(:name=).and_return('Cute kittens')
        picture.should_receive(:name).and_return('Cute kittens')
        picture.should_receive(:save!).and_return(true)
      end

      context 'if inside of archive overlay' do
        let(:params)  { {element_id: 1, content_id: 1} }
        let(:element) { mock_model('Element') }
        let(:content) { mock_model('Content') }

        before do
          Content.stub_chain(:select, :find_by_id).and_return(content)
          Element.stub_chain(:select, :find_by_id).and_return(element)
        end

        it "assigns lots of instance variables" do
          subject
          assigns(:options).should eq({})
          assigns(:while_assigning).should be_true
          assigns(:content).should eq(content)
          assigns(:element).should eq(element)
          assigns(:page).should eq(1)
          assigns(:per_page).should eq(9)
        end
      end

      context 'with size param given' do
        let(:params) { {size: '200x200'} }
        before { subject }
        it { assigns(:size).should eq('200x200') }
      end

      context 'without size param given' do
        let(:params) { {size: nil} }
        before { subject }
        it { assigns(:size).should eq('medium') }
      end

      context 'without session key in params' do
        it "redirects to picture archive" do
          should redirect_to(admin_pictures_path(filter: 'last_upload'))
        end
      end

      context 'with session key in params' do
        let(:params) { {format: 'js'} }

        before { params['_dummy_session'] = 'kjhg' }

        it "renders javascript" do
          should render_template(:create)
        end
      end
    end

    describe '#edit_multiple' do
      let(:pictures) { [mock_model('Picture')] }
      before { Picture.should_receive(:find).and_return(pictures) }

      it 'assigns pictures instance variable' do
        get :edit_multiple
        assigns(:pictures).should eq(pictures)
      end
    end

    describe '#update' do
      subject { put :update, picture: {name: ''} }

      let(:picture) { mock_model('Picture', name: 'Cute kitten') }

      before do
        Picture.should_receive(:find).and_return(picture)
      end

      context 'with passing validations' do
        before do
          picture.should_receive(:update_attributes).and_return(true)
        end

        it "sets success notice" do
          subject
          flash[:notice].should_not be_blank
        end

        it "redirects to index path" do
          should redirect_to admin_pictures_path
        end
      end

      context 'with failing validations' do
        before do
          picture.should_receive(:update_attributes).and_return(false)
        end

        it "sets success notice and redirects to index path" do
          subject
          flash[:error].should_not be_blank
        end

        it "redirects to index path" do
          should redirect_to admin_pictures_path
        end
      end
    end

    describe '#update_multiple' do
      let(:picture)  { mock_model('Picture') }
      let(:pictures) { [picture] }

      before do
        Picture.should_receive(:find).and_return(pictures)
      end

      it "loads and assigns pictures" do
        post :update_multiple
        assigns(:pictures).should eq(pictures)
      end

      it "updates each picture" do
        picture.should_receive(:tag_list=)
        picture.should_receive(:save)
        post :update_multiple
      end

      context 'with pictures_name given in params' do
        it "updates each picture's name" do
          picture.should_receive(:name=).with('Cute kitten')
          picture.should_receive(:tag_list=)
          picture.should_receive(:save)
          post :update_multiple, pictures_name: 'Cute kitten'
        end
      end
    end

    describe "#delete_multiple" do
      subject { delete :delete_multiple, picture_ids: picture_ids }

      let(:deletable_picture)     { mock_model('Picture', name: 'pic of the pig', deletable?: true) }
      let(:not_deletable_picture) { mock_model('Picture', name: 'pic of the chick', deletable?: false) }

      context "no picture_ids given" do
        let(:picture_ids) { '' }

        it "should give a warning about not deleting any pictures" do
          subject
          expect(flash[:warn]).to match('Could not delete Pictures')
        end
      end

      context "picture_ids given" do
        context "all are deletable" do
          let(:picture_ids) { "#{deletable_picture.id}" }

          before do
            Picture.stub(:find).and_return([deletable_picture])
          end

          it "should delete the pictures give a notice about deleting them" do
            subject
            expect(flash[:notice]).to match('successfully')
          end
        end

        context "deletable and not deletable" do
          let(:picture_ids) { "#{deletable_picture.id},#{not_deletable_picture.id}" }

          before do
            Picture.stub(:find).and_return([deletable_picture, not_deletable_picture])
          end

          it "should give a warning for the non deletable pictures and delete the others" do
            deletable_picture.should_receive(:destroy)
            subject
            expect(flash[:warn]).to match('could not be deleted')
          end
        end

        context 'with error happening' do
          let(:picture_ids) { "#{deletable_picture.id}" }

          before do
            Picture.should_receive(:find).and_raise('yada')
          end

          it "sets error message" do
            subject
            flash[:error].should_not be_blank
          end

          it "redirects to index" do
            subject
            response.should redirect_to admin_pictures_path
          end
        end
      end
    end

    describe '#destroy' do
      let(:picture) { mock_model('Picture', name: 'Cute kitten') }

      before do
        Picture.should_receive(:find).and_return(picture)
      end

      it "destroys the picture and sets and success message" do
        picture.should_receive(:destroy)
        delete :destroy
        assigns(:picture).should eq(picture)
        flash[:notice].should_not be_blank
      end

      context 'if an error happens' do
        before do
          picture.should_receive(:destroy).and_raise('yada')
        end

        it "shows error notice" do
          delete :destroy
          flash[:error].should_not be_blank
        end

        it "redirects to index" do
          delete :destroy
          response.should redirect_to admin_pictures_path
        end
      end
    end

    describe '#flush' do
      it "removes the complete pictures cache" do
        FileUtils.should_receive(:rm_rf).with(Rails.root.join('public', '', 'pictures'))
        post :flush
      end
    end

  end
end
