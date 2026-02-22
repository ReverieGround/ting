import { useState } from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  Platform,
  Modal,
  View,
} from 'react-native';
import DateTimePicker, {
  DateTimePickerEvent,
} from '@react-native-community/datetimepicker';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../theme/colors';

interface Props {
  date: Date;
  onDateChange: (date: Date) => void;
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const h = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  return `${y}. ${m}. ${day}  ${h}:${min}`;
}

export default function DatePickerButton({ date, onDateChange }: Props) {
  const [showPicker, setShowPicker] = useState(false);
  const [tempDate, setTempDate] = useState(date);

  const onChange = (_: DateTimePickerEvent, selected?: Date) => {
    if (Platform.OS === 'android') {
      setShowPicker(false);
      if (selected) onDateChange(selected);
    } else if (selected) {
      setTempDate(selected);
    }
  };

  const confirmIOS = () => {
    onDateChange(tempDate);
    setShowPicker(false);
  };

  return (
    <>
      <TouchableOpacity
        style={styles.button}
        onPress={() => {
          setTempDate(date);
          setShowPicker(true);
        }}
      >
        <Ionicons name="calendar-outline" size={18} color={colors.hint} />
        <Text style={styles.text}>{formatDate(date)}</Text>
      </TouchableOpacity>

      {showPicker && Platform.OS === 'android' && (
        <DateTimePicker
          value={tempDate}
          mode="datetime"
          onChange={onChange}
          maximumDate={new Date()}
        />
      )}

      {showPicker && Platform.OS === 'ios' && (
        <Modal transparent animationType="slide">
          <View style={styles.overlay}>
            <View style={styles.sheet}>
              <View style={styles.sheetHeader}>
                <TouchableOpacity onPress={() => setShowPicker(false)}>
                  <Text style={styles.cancelText}>취소</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={confirmIOS}>
                  <Text style={styles.doneText}>완료</Text>
                </TouchableOpacity>
              </View>
              <DateTimePicker
                value={tempDate}
                mode="datetime"
                display="spinner"
                onChange={onChange}
                maximumDate={new Date()}
                textColor={colors.primary}
              />
            </View>
          </View>
        </Modal>
      )}
    </>
  );
}

const styles = StyleSheet.create({
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
  },
  text: {
    fontSize: 14,
    color: colors.hint,
  },
  overlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    backgroundColor: colors.bgDark,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    paddingBottom: 34,
  },
  sheetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: spacing.md,
  },
  cancelText: { fontSize: 16, color: colors.hint },
  doneText: { fontSize: 16, color: '#C7F464', fontWeight: '600' },
});
