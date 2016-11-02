require 'spec_helper'

def add_title_slice(text)
  select 'Title', from: 'add-slice-option'
  within("#container-container_one ul.slices-holder > li:last-child") do
    fill_in 'Title', with: text
  end
end

describe "Add/Edit/Delete slices on a page", type: :request, js: true do
  before do
    home, @page = StandardTree.build_minimal_with_slices
    sign_in_as_admin
    @new_slice_id = '#slice-__new__0'
    visit "/admin/pages/#{@page.id}"
  end

  context "Adding" do
    before do
      select 'Title', from: 'add-slice-option'
    end

    it "1 slice" do
      click_on 'Save'

      within @new_slice_id do
        expect(page).to have_css ".field-with-errors"
        fill_in 'Title', with: 'New slice title'
      end

      click_on 'Save'

      expect(page).to have_no_css '#container-slices .field-with-errors'
    end

    it "1 slice reloaded shouldn't duplicate itself" do
      within(@new_slice_id) do
        fill_in 'Title', with: 'New slice title'
      end
      click_on_save_changes

      expect(page).to have_no_css('#container-slices .field-with-errors')

      wait_for_ajax

      visit "/admin/pages/#{@page.id}"

      within('ul.slices-holder li:first-child.slice') do
        fill_in 'Title', with: 'one'
      end
      click_on_save_changes

      expect(page).to have_no_css(@new_slice_id)
    end

    it "three slices added in order should stay in that order when reloaded" do
      within(@new_slice_id) do
        fill_in 'Title', with: 'one'
      end
      add_title_slice('two')
      add_title_slice('three')
      add_title_slice('four')
      click_on_save_changes

      within('#container-container_one .slice:nth-child(2)') do
        expect(find_field('Title').value).to eq('one')
      end
      within('#container-container_one .slice:nth-child(3)') do
        expect(find_field('Title').value).to eq('two')
      end
      within('#container-container_one .slice:nth-child(4)') do
        expect(find_field('Title').value).to eq('three')
      end
    end
  end

  context "Deleting" do
    it "1 slice is deleted" do
      click_on 'Delete'
      click_on_save_changes
      expect(find('.slices-holder li.slice', visible: false)).to_not be_visible
    end
  end
end

describe 'Edit slices on all entries in a set', type: :request, js: true do
  def set_entries_page
    "/admin/pages/#{@page.id}?entries=1"
  end

  before do
    home, parent = StandardTree.build_minimal
    sign_in_as_admin
    @page, articles = StandardTree.add_article_set(home)
    @new_slice_id = '#slice-__new__0'
    visit set_entries_page
  end

  context "Editing" do
    it "a textile slice" do
      first_slice_selector = 'ul.slices-holder li:first-child.slice'
      new_copy = 'New copy for this slice'
      within(first_slice_selector) do
        fill_in 'textile', with: new_copy
      end

      click_on_save_changes
      visit set_entries_page
      wait_for_ajax
      expect(page).to have_css(first_slice_selector + ' textarea', text: new_copy)
    end
  end
end

describe 'Page data and meta-data', type: :request, js: true do
  before do
    home, @page = StandardTree.build_minimal_with_slices
    sign_in_as_admin
    visit "/admin/pages/#{@page.id}"
  end

  it "Meta fields" do
    updated_parent = 'new-parent'
    updated_description = 'This page is very interesting'

    click_on "advanced options…"
    fill_in 'meta-permalink', with: updated_parent
    fill_in 'meta-meta_description', with: updated_description

    click_on 'Save'
    expect(page).to have_field 'meta-permalink', with: updated_parent
    expect(page).to have_field 'meta-meta_description', with: updated_description
  end
end
