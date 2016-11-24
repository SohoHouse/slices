require 'spec_helper'

describe "A site with snippets", type: :request do
  before do
    home, page = StandardTree.build_minimal
    page.update_attributes(layout: 'layout_two')
  end

  it "renders snippets with plain text" do
    Snippet.create(key: 'address', value: '100 de Beauvoir Road')
    visit '/parent'

    expect(page).to have_css 'footer p.text', '100 de Beauvoir Road'
  end

  it "renders snippets with html" do
    Snippet.create(key: 'address.html', value: '100 de Beauvoir Road<br />London')
    visit '/parent'

    expect(page).to have_css 'footer p.html br'
  end

  it "renders snippets with symbols" do
    Snippet.create(key: 'en.address', value: 'nb:')
    visit '/parent'

    expect(page).to have_css 'footer p', 'nb:'
  end

  it "renders nothing if the snippet has no value" do
    Snippet.create(key: 'en.address', value: '')
    visit '/parent'

    expect(page).to have_css 'footer p', ''
  end
end
