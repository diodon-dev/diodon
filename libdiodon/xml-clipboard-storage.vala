/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2011 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */

namespace Diodon
{
    /**
     * Xml clipboard storage implementation using
     * libxml2 to store parse and write the xml file.
     * Xml will always be flushed after storage has changed.
     */
    class XmlClipboardStorage : GLib.Object, IClipboardStorage
    {
        private Gee.List<IClipboardItem> items;
        private string xml_file;
    
        /**
         * Xml file constructor.
         * 
         * @param directory directory file is located
         * @param file xml file name
         */
        public XmlClipboardStorage(string directory, string file)
        {
            items = new Gee.ArrayList<IClipboardItem>((GLib.EqualFunc?)IClipboardItem.equal_func);
            
            if(Utility.make_directory_with_parents(directory)) {
                xml_file = Path.build_filename(directory, file);
                load();
            }
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void remove_item(IClipboardItem item)
        {
            items.remove(item);
            write();
        }
        
        /**
	     * {@inheritDoc}
	     */
        public Gee.List<IClipboardItem> get_items()
        {
            return items;
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void add_item(IClipboardItem item)
        {
            items.add(item);
            write();
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void clear()
        {
            items.clear();
            write();
        }
        
        /**
         * Load storage xml to memory
         */
        public void load()
        {   
            debug("Read storage file " + xml_file);
            Xml.TextReader reader = new Xml.TextReader.filename(xml_file);
            
            while(reader.read() == 1) {
                // import node when it is a item element
                if("item" == reader.name() && reader.node_type() == 1) {
                
                    // get type of item with text item as fallback
                    string type_name = reader.get_attribute("type");
                    if(type_name == null || type_name == "") {
                        // define text as fallback
                        type_name = typeof(TextClipboardItem).name();
                    }
                    
                    // get value and check if it is valid
                    string value = reader.read_string();
                    if(value != null && value.validate()) {
                        debug("Add item of type " + type_name + " with value \"" + 
                              value + "\" to clipboard.");
                        
                        // FIXME: get this up and running avoiding if, else clauses
                        // create item with reflection
                        // Type type = Type.from_name(type_name);
                        // IClipboardItem item = (IClipboardItem)Object.new(type, ClipboardType.NONE, value);
                        // items.add(item);
                        
                        try {
                            IClipboardItem item = null;
                            if(type_name == typeof(FileClipboardItem).name()) {
                                item = new FileClipboardItem(ClipboardType.NONE, value);
                            } else if(type_name == typeof(ImageClipboardItem).name()) {
                                item = new ImageClipboardItem(ClipboardType.NONE, value);
                            } else {
                                item = new TextClipboardItem(ClipboardType.NONE, value);
                            }
                            
                            items.add(item);
                        } catch (Error e) {
                            warning ("loading of item of type %s with data %s failed. Cause: %s",
                                type_name, value, e.message);
                        }                        
                    }
                }    
            }
        }
        
        /**
         * Write storage to xml file
         */
        public void write()
        {
            Xml.TextWriter writer = new Xml.TextWriter.filename(xml_file);
            writer.set_indent(true);
            writer.set_indent_string ("\t");

            writer.start_document ("1.0", "UTF-8");
            writer.start_element ("clipboard");
            
            foreach(IClipboardItem item in items) {
                writer.start_element("item");
                writer.write_attribute("type", item.get_type().name());
                writer.write_string(item.get_clipboard_data());
                writer.end_element();
            }          
            
            writer.end_element();
            writer.end_document();
            
            writer.flush();
        }
    }  
}
 
